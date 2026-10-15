package com.symbolrandomgame.backend.application.model;

import java.time.LocalDate;

public record PuntuacionData(
        int idPuntuacion,
        int idUsuario,
        String jugador,
        String modo,
        int incremento,
        int vidas,
        int tiempoPregunta,
        int tiempoTotal,
        int resultado,
        LocalDate fechaNacimiento
) {}
