package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.application.model.GuardarPuntuacionCommand;
import com.symbolrandomgame.backend.application.model.PuntuacionResponse;

public interface PuntuacionUseCase {
    java.util.List<PuntuacionResponse> obtenerTodas();
    void eliminar(int idPuntuacion, int idUsuario);
    void guardar(GuardarPuntuacionCommand request);
}
