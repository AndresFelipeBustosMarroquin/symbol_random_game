package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.application.model.ConfiguracionCommand;
import com.symbolrandomgame.backend.application.model.ConfiguracionResponse;

public interface ConfiguracionUseCase {
    ConfiguracionResponse obtener(int idUsuario);
    ConfiguracionResponse guardar(int idUsuario, ConfiguracionCommand request);
}
