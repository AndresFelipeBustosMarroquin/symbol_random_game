package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.exception.UseCaseException;
import com.symbolrandomgame.backend.application.model.GuardarPuntuacionCommand;
import com.symbolrandomgame.backend.application.model.ModoData;
import com.symbolrandomgame.backend.application.model.NivelData;
import com.symbolrandomgame.backend.application.model.PuntuacionData;
import com.symbolrandomgame.backend.application.model.PuntuacionResponse;
import com.symbolrandomgame.backend.application.port.in.PuntuacionUseCase;
import com.symbolrandomgame.backend.application.port.out.PuntuacionOperationsPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.List;
import java.util.Locale;

@Service
public class PuntuacionService implements PuntuacionUseCase {
    private static final List<String> MODOS =
            List.of("NUMEROS", "CARACTERES", "SIMBOLOS", "OPERACIONES");
    private final PuntuacionOperationsPort operationsPort;

    public PuntuacionService(PuntuacionOperationsPort operationsPort) {
        this.operationsPort = operationsPort;
    }

    @Override
    public List<PuntuacionResponse> obtenerTodas() {
        return operationsPort.obtenerTodas().stream()
                .map(this::respuesta)
                .toList();
    }

    @Override
    @Transactional
    public void eliminar(int idPuntuacion, int idUsuario) {
        if (idPuntuacion <= 0 || idUsuario <= 0) {
            throw new UseCaseException(400, "Los identificadores no son válidos");
        }
        if (operationsPort.eliminarPartidaPropia(idPuntuacion, idUsuario) == 0) {
            if (!operationsPort.puntuacionExiste(idPuntuacion)) {
                throw new UseCaseException(404, "La puntuación no existe");
            }
            throw new UseCaseException(
                    403, "Solo puedes eliminar tus propias puntuaciones"
            );
        }
    }

    @Override
    @Transactional
    public void guardar(GuardarPuntuacionCommand request) {
        validar(request);
        if (!operationsPort.usuarioExiste(request.idUsuario())) {
            throw new UseCaseException(404, "El usuario no existe");
        }

        String modoNombre = nombreCanonico(request.modo());
        String modoNormalizado = normalizar(modoNombre);
        Integer modoId = operationsPort.modos().stream()
                .filter(modo -> normalizar(modo.nombre()).equals(modoNormalizado))
                .map(ModoData::id).findFirst().orElse(null);
        if (modoId == null) modoId = operationsPort.crearModo(modoNombre);
        if (modoId == null) throw new IllegalStateException("No se pudo crear el modo de juego");

        String nivelNombre = "PERSONALIZADO I%d T%d V%d".formatted(
                request.digitos(), request.tiempoPregunta(), request.vidas()
        );
        NivelData nivel = operationsPort.guardarNivel(
                modoId, nivelNombre, request.digitos(),
                request.tiempoPregunta(), request.vidas()
        );
        if (nivel == null) throw new IllegalStateException("No se pudo guardar el nivel");

        LocalDateTime fin = LocalDateTime.now();
        LocalDateTime inicio = fin.minusSeconds(request.tiempoTotal());
        int partidaId = operationsPort.crearPartida(
                request.idUsuario(), modoId, nivel.id(), inicio, fin, request.resultado()
        );
        operationsPort.guardarPuntuacion(nivel, request, partidaId);
    }

    private PuntuacionResponse respuesta(PuntuacionData score) {
        return new PuntuacionResponse(
                score.idPuntuacion(), score.idUsuario(), score.jugador(),
                nombreCanonico(score.modo()), score.incremento(), score.vidas(),
                score.tiempoPregunta(), score.tiempoTotal(), score.resultado(),
                Period.between(score.fechaNacimiento(), LocalDate.now()).getYears()
        );
    }

    private void validar(GuardarPuntuacionCommand request) {
        if (request == null || request.idUsuario() == null || request.idUsuario() <= 0
                || request.modo() == null || !MODOS.contains(normalizar(request.modo()))
                || request.digitos() == null || request.digitos() <= 0
                || request.vidas() == null || request.vidas() <= 0
                || request.tiempoPregunta() == null || request.tiempoPregunta() <= 0
                || request.tiempoTotal() == null || request.tiempoTotal() < 0
                || request.resultado() == null || request.resultado() < 0) {
            throw new UseCaseException(
                    400, "Los datos de la puntuación no son válidos"
            );
        }
    }

    private String nombreCanonico(String modo) {
        return switch (normalizar(modo)) {
            case "NUMEROS" -> "NÚMEROS";
            case "CARACTERES" -> "CARACTERES";
            case "SIMBOLOS" -> "SÍMBOLOS";
            case "OPERACIONES" -> "OPERACIONES";
            default -> throw new UseCaseException(400, "El modo de juego no es válido");
        };
    }

    private String normalizar(String value) {
        String normalized = Normalizer.normalize(value.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toUpperCase(Locale.ROOT)
                .replaceAll("[^A-Z0-9]", "");
        return switch (normalized) {
            case "NMEROS" -> "NUMEROS";
            case "SMBOLOS" -> "SIMBOLOS";
            default -> normalized;
        };
    }
}
