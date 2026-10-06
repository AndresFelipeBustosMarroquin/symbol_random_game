package com.symbolrandomgame.backend.infrastructure.adapter.in;

public record ConfiguracionResponse(
        int incremento,
        int vidas,
        int tiempo,
        int sonido,
        int paleta,
        double volumen,
        int fuente
) {
    public static ConfiguracionResponse predeterminada() {
        return new ConfiguracionResponse(1, 1, 5, 0, 0, 0.5, 0);
    }
}
