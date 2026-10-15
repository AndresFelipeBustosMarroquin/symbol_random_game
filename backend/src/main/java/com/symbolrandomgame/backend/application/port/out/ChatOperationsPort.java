package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.application.model.MensajeResponse;

public interface ChatOperationsPort {
    boolean amistadAceptada(int idUsuario, int idAmigo);
    java.util.List<MensajeResponse> mensajes(int idUsuario, int idAmigo);
    void marcarVistos(int idUsuario, int idAmigo, long ultimoMensaje);
    MensajeResponse guardar(int idUsuario, int idAmigo, String contenido);
}
