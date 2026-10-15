package com.symbolrandomgame.backend.application.model;

import java.time.LocalDate;

public record PerfilResponse(
        int idUsuario,
        String nombreUso,
        LocalDate fechaNacimiento,
        String descripcion,
        String avatar,
        int partidas,
        int mejorPuntuacion,
        long puntosTotales,
        int partidasNumeros,
        int mejorNumeros,
        int partidasCaracteres,
        int mejorCaracteres,
        int partidasSimbolos,
        int mejorSimbolos,
        int partidasOperaciones,
        int mejorOperaciones
) {}
