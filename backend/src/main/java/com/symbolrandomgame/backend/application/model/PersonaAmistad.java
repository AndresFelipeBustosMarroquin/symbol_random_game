package com.symbolrandomgame.backend.application.model;

public record PersonaAmistad(
        int idUsuario,
        String nombreUso,
        String avatar,
        int mensajesNoVistos
) {}
