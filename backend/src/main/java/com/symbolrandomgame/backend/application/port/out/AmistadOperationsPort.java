package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.application.model.AmistadRegistro;
import com.symbolrandomgame.backend.application.model.PersonaAmistad;

public interface AmistadOperationsPort {
    boolean usuarioExiste(int idUsuario);
    java.util.List<PersonaAmistad> amigos(int idUsuario);
    java.util.List<PersonaAmistad> solicitudes(int idUsuario, boolean enviadas);
    AmistadRegistro estado(int idUsuario, int idOtro);
    int insertarSolicitud(int idUsuario, int idDestino);
    int aceptarSolicitud(int idUsuario, int idOtro);
    void eliminar(int idUsuario, int idOtro);
}
