package com.symbolrandomgame.backend.application.model;

public record ActualizarPerfilCommand(String nombreUso, java.time.LocalDate fechaNacimiento, String descripcion, String avatar) {}
