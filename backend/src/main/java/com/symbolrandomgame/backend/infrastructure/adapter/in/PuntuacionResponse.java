package com.symbolrandomgame.backend.infrastructure.adapter.in;

public record PuntuacionResponse(
        int idPuntuacion,
        int idUsuario,
        String jugador,
        String modo,
        int incremento,
        int vidas,
        int tiempoPregunta,
        int tiempoTotal,
        int resultado,
        int edad
) {
}
