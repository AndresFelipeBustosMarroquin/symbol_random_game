package com.symbolrandomgame.backend.infrastructure.adapter.in;

public record GuardarPuntuacionRequest(
        Integer idUsuario,
        String modo,
        Integer digitos,
        Integer vidas,
        Integer tiempoPregunta,
        Integer tiempoTotal,
        Integer resultado
) {
}
