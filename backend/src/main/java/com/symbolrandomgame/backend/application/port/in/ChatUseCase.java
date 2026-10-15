package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.application.model.MensajeResponse;

public interface ChatUseCase {
    java.util.List<MensajeResponse> obtener(int idUsuario, int idAmigo);
    MensajeResponse enviar(int idUsuario, int idAmigo, String contenido);
}
