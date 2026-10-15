package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.application.model.ActualizarPerfilCommand;
import com.symbolrandomgame.backend.application.model.PerfilResponse;
import com.symbolrandomgame.backend.application.model.PerfilUpdateResult;

public interface PerfilOperationsPort {
    boolean usuarioExiste(int idUsuario);
    PerfilResponse obtener(int idUsuario);
    PerfilUpdateResult actualizar(int idUsuario, ActualizarPerfilCommand request);
}
