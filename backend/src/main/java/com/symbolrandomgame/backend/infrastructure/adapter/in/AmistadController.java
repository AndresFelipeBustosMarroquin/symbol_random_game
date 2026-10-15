package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.port.in.AmistadUseCase;
import com.symbolrandomgame.backend.application.model.AmistadesResponse;
import com.symbolrandomgame.backend.application.model.EstadoAmistadResponse;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/amistades")
public class AmistadController {
    private final AmistadUseCase amistadUseCase;

    public AmistadController(AmistadUseCase amistadUseCase) {
        this.amistadUseCase = amistadUseCase;
    }

    @GetMapping
    public AmistadesResponse obtener(@PathVariable int idUsuario) {
        return ControllerErrors.translate(() -> amistadUseCase.obtener(idUsuario));
    }

    @GetMapping("/{idOtro}")
    public EstadoAmistadResponse estado(
            @PathVariable int idUsuario,
            @PathVariable int idOtro
    ) {
        return ControllerErrors.translate(() -> amistadUseCase.estado(idUsuario, idOtro));
    }

    @PostMapping("/{idDestino}")
    public EstadoAmistadResponse solicitar(
            @PathVariable int idUsuario,
            @PathVariable int idDestino
    ) {
        return ControllerErrors.translate(() -> amistadUseCase.solicitar(idUsuario, idDestino));
    }

    @PostMapping("/{idOtro}/aceptar")
    public EstadoAmistadResponse aceptar(
            @PathVariable int idUsuario,
            @PathVariable int idOtro
    ) {
        return ControllerErrors.translate(() -> amistadUseCase.aceptar(idUsuario, idOtro));
    }

    @DeleteMapping("/{idOtro}")
    public void eliminar(
            @PathVariable int idUsuario,
            @PathVariable int idOtro
    ) {
        ControllerErrors.translate(() -> amistadUseCase.eliminar(idUsuario, idOtro));
    }
}
