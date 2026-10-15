package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.application.model.AmistadesResponse;
import com.symbolrandomgame.backend.application.model.EstadoAmistadResponse;

public interface AmistadUseCase {
    AmistadesResponse obtener(int idUsuario);
    EstadoAmistadResponse estado(int idUsuario, int idOtro);
    EstadoAmistadResponse solicitar(int idUsuario, int idDestino);
    EstadoAmistadResponse aceptar(int idUsuario, int idOtro);
    void eliminar(int idUsuario, int idOtro);
}
