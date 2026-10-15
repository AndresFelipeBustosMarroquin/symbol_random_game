package com.symbolrandomgame.backend.application.model;

import java.util.List;

public record AmistadesResponse(
        List<PersonaAmistad> amigos,
        List<PersonaAmistad> recibidas,
        List<PersonaAmistad> enviadas
) {}
