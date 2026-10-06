package com.symbolrandomgame.backend.infrastructure.adapter.in;

public record ConfiguracionRequest(
        Integer incremento,
        Integer vidas,
        Integer tiempo,
        Integer sonido,
        Integer paleta,
        Double volumen,
        Integer fuente
) {
}
