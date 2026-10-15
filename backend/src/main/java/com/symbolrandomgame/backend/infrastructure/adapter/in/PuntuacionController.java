package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.model.GuardarPuntuacionCommand;
import com.symbolrandomgame.backend.application.model.PuntuacionResponse;
import com.symbolrandomgame.backend.application.port.in.PuntuacionUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/puntuaciones")
public class PuntuacionController {
    private final PuntuacionUseCase puntuacionUseCase;

    public PuntuacionController(PuntuacionUseCase puntuacionUseCase) {
        this.puntuacionUseCase = puntuacionUseCase;
    }

    @GetMapping
    public List<PuntuacionResponse> obtenerTodas() {
        return ControllerErrors.translate(puntuacionUseCase::obtenerTodas);
    }

    @DeleteMapping("/{idPuntuacion}")
    public void eliminar(
            @PathVariable int idPuntuacion,
            @RequestParam int idUsuario
    ) {
        ControllerErrors.translate(
                () -> puntuacionUseCase.eliminar(idPuntuacion, idUsuario)
        );
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public void guardar(@RequestBody GuardarPuntuacionRequest request) {
        GuardarPuntuacionCommand command = request == null
                ? null
                : new GuardarPuntuacionCommand(
                        request.idUsuario(),
                        request.modo(),
                        request.digitos(),
                        request.vidas(),
                        request.tiempoPregunta(),
                        request.tiempoTotal(),
                        request.resultado()
                );
        ControllerErrors.translate(() -> puntuacionUseCase.guardar(command));
    }
}
