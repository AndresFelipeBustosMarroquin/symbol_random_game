package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.application.model.ActualizarPerfilCommand;
import com.symbolrandomgame.backend.application.model.PerfilResponse;

public interface PerfilUseCase {
    PerfilResponse obtener(int idUsuario);
    PerfilResponse actualizar(int idUsuario, ActualizarPerfilCommand request);
}
