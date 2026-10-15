package com.symbolrandomgame.backend.application.model;

public record ConfiguracionData(
        int incremento,
        int vidas,
        int tiempo,
        int sonido,
        String paleta,
        double volumen,
        int fuente
) {}
