package com.symbolrandomgame.backend.application.model;

public record GuardarPuntuacionCommand(Integer idUsuario, String modo, Integer digitos, Integer vidas, Integer tiempoPregunta, Integer tiempoTotal, Integer resultado) {}
