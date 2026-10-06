package com.symbolrandomgame.backend.domain.model;

import java.time.LocalDate;

public class Usuario {

    private Integer idUsuario;
    private String nombreUso;
    private String contrasenaUs;
    private LocalDate fechaNacimiento;

    public Usuario() {
    }

    public Usuario(
            Integer idUsuario,
            String nombreUso,
            String contrasenaUs,
            LocalDate fechaNacimiento
    ) {
        this.idUsuario = idUsuario;
        this.nombreUso = nombreUso;
        this.contrasenaUs = contrasenaUs;
        this.fechaNacimiento = fechaNacimiento;
    }

    public Integer getIdUsuario() {
        return idUsuario;
    }

    public void setIdUsuario(Integer idUsuario) {
        this.idUsuario = idUsuario;
    }

    public String getNombreUso() {
        return nombreUso;
    }

    public void setNombreUso(String nombreUso) {
        this.nombreUso = nombreUso;
    }

    public String getContrasenaUs() {
        return contrasenaUs;
    }

    public void setContrasenaUs(String contrasenaUs) {
        this.contrasenaUs = contrasenaUs;
    }

    public LocalDate getFechaNacimiento() {
        return fechaNacimiento;
    }

    public void setFechaNacimiento(LocalDate fechaNacimiento) {
        this.fechaNacimiento = fechaNacimiento;
    }
}