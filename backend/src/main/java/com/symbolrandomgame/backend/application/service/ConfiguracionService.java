package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.model.ConfiguracionCommand;
import com.symbolrandomgame.backend.application.model.ConfiguracionData;
import com.symbolrandomgame.backend.application.model.ConfiguracionResponse;
import com.symbolrandomgame.backend.application.model.PaletaData;
import com.symbolrandomgame.backend.application.port.in.ConfiguracionUseCase;
import com.symbolrandomgame.backend.application.port.out.ConfiguracionOperationsPort;
import com.symbolrandomgame.backend.application.exception.UseCaseException;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;

@Service
public class ConfiguracionService implements ConfiguracionUseCase {
    private final ConfiguracionOperationsPort operationsPort;

    public ConfiguracionService(ConfiguracionOperationsPort operationsPort) {
        this.operationsPort = operationsPort;
    }

    @Override
    public ConfiguracionResponse obtener(int idUsuario) {
        validarUsuario(idUsuario);
        var data = operationsPort.obtener(idUsuario);
        if (data == null) return ConfiguracionResponse.predeterminada();
        return new ConfiguracionResponse(
                data.incremento(), data.vidas(), data.tiempo(), data.sonido(),
                indicePaleta(data.paleta()), data.volumen(), data.fuente()
        );
    }

    @Override
    public ConfiguracionResponse guardar(int idUsuario, ConfiguracionCommand request) {
        validarUsuario(idUsuario);
        if (request == null || request.incremento() == null || request.incremento() < 1
                || request.incremento() > 5 || request.vidas() == null
                || request.vidas() < 1 || request.vidas() > 5 || request.tiempo() == null
                || request.tiempo() < 1 || request.tiempo() > 60 || request.sonido() == null
                || request.sonido() < 0 || request.sonido() > 5 || request.paleta() == null
                || request.paleta() < 0 || request.paleta() >= PALETAS.size()
                || request.volumen() == null || request.volumen() < 0 || request.volumen() > 1
                || request.fuente() == null || request.fuente() < 0 || request.fuente() > 6) {
            throw new UseCaseException(400, "Las preferencias no son válidas");
        }
        String nombrePaleta = PALETAS.get(request.paleta());
        Integer idPaleta = operationsPort.paletas().stream()
                .filter(p -> normalizar(p.nombre()).equals(normalizar(nombrePaleta)))
                .map(PaletaData::id).findFirst().orElse(null);
        if (idPaleta == null) {
            throw new IllegalStateException("No se encontró la paleta " + nombrePaleta);
        }
        Integer idAvatar = operationsPort.avatarActual(idUsuario);
        if (idAvatar == null) idAvatar = operationsPort.avatarPredeterminado();
        if (idAvatar == null) {
            throw new IllegalStateException("No hay un avatar predeterminado disponible");
        }
        operationsPort.guardar(idUsuario, request, idPaleta, idAvatar);
        return obtener(idUsuario);
    }

    private static final List<String> PALETAS =
            List.of("Violeta", "Océano", "Esmeralda", "Atardecer", "Ámbar", "Rojo");

    private void validarUsuario(int idUsuario) {
        if (!operationsPort.usuarioExiste(idUsuario)) {
            throw new UseCaseException(404, "El usuario no existe");
        }
    }

    private int indicePaleta(String nombre) {
        for (int i = 0; i < PALETAS.size(); i++) {
            if (normalizar(PALETAS.get(i)).equals(normalizar(nombre))) return i;
        }
        return 0;
    }

    private String normalizar(String value) {
        return Normalizer.normalize(value.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toUpperCase(Locale.ROOT);
    }
}
