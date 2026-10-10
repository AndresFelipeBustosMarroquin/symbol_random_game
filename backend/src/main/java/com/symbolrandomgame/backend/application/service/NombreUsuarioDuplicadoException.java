package com.symbolrandomgame.backend.application.service;

public class NombreUsuarioDuplicadoException extends RuntimeException {

    public NombreUsuarioDuplicadoException(String nombreUso) {
        super("El nombre de usuario ya está registrado: " + nombreUso);
    }

    public NombreUsuarioDuplicadoException(String nombreUso, Throwable cause) {
        super("El nombre de usuario ya está registrado: " + nombreUso, cause);
    }
}
