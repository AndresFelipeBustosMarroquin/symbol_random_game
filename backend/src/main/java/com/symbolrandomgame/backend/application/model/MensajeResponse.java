package com.symbolrandomgame.backend.application.model;

import java.sql.Timestamp;

public record MensajeResponse(
        long idMensaje,
        int idEmisor,
        String emisor,
        String contenido,
        Timestamp fechaEnvio
) {}
