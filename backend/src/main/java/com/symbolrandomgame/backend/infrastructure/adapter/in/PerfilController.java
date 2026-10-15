package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.model.ActualizarPerfilCommand;
import com.symbolrandomgame.backend.application.model.PerfilResponse;
import com.symbolrandomgame.backend.application.port.in.PerfilUseCase;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/perfil")
public class PerfilController {
    private final PerfilUseCase perfilUseCase;

    public PerfilController(PerfilUseCase perfilUseCase) {
        this.perfilUseCase = perfilUseCase;
    }

    @GetMapping
    public PerfilResponse obtener(@PathVariable int idUsuario) {
        return ControllerErrors.translate(() -> perfilUseCase.obtener(idUsuario));
    }

    @PutMapping
    public PerfilResponse actualizar(
            @PathVariable int idUsuario,
            @RequestBody ActualizarPerfilRequest request
    ) {
        ActualizarPerfilCommand command = request == null
                ? null
                : new ActualizarPerfilCommand(
                        request.nombreUso(),
                        request.fechaNacimiento(),
                        request.descripcion(),
                        request.avatar()
                );
        return ControllerErrors.translate(() -> perfilUseCase.actualizar(idUsuario, command));
    }

    public record ActualizarPerfilRequest(
            String nombreUso,
            LocalDate fechaNacimiento,
            String descripcion,
            String avatar
    ) {}
}
