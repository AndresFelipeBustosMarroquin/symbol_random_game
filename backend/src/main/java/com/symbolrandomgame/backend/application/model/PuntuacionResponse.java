package com.symbolrandomgame.backend.application.model;

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
) {}
