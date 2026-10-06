package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.domain.model.Usuario;

import java.time.LocalDate;

public record UsuarioResumenResponse(
        Integer idUsuario,
        String nombreUso,
        LocalDate fechaNacimiento
) {
    public static UsuarioResumenResponse from(Usuario usuario) {
        return new UsuarioResumenResponse(
                usuario.getIdUsuario(),
                usuario.getNombreUso(),
                usuario.getFechaNacimiento()
        );
    }
}
