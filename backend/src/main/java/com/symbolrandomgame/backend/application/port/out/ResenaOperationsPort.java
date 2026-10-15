package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.application.model.GuardarResenaCommand;
import com.symbolrandomgame.backend.application.model.ResenaResponse;

public interface ResenaOperationsPort {
    boolean usuarioExiste(int idUsuario);
    java.util.List<ResenaResponse> obtener(int idPerfil);
    ResenaResponse guardar(int idPerfil, GuardarResenaCommand request);
}
