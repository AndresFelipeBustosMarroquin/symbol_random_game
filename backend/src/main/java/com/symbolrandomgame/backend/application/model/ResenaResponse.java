package com.symbolrandomgame.backend.application.model;

import java.sql.Timestamp;

public record ResenaResponse(
        int idAutor,
        String autor,
        String avatar,
        String contenido,
        Timestamp fechaCreacion
) {}
