package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.application.model.GuardarResenaCommand;
import com.symbolrandomgame.backend.application.model.ResenaResponse;

public interface ResenaUseCase {
    java.util.List<ResenaResponse> obtener(int idPerfil);
    ResenaResponse guardar(int idPerfil, GuardarResenaCommand request);
}
