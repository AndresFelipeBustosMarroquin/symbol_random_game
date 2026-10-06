package com.symbolrandomgame.backend.infrastructure.adapter.out;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "usuario")
public class UsuarioEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_usuario")
    private Integer idUsuario;

    @Column(name = "nombre_uso", nullable = false, unique = true)
    private String nombreUso;

    @Column(name = "contrasena_us", nullable = false)
    private String contrasenaUs;

    @Column(name = "fecha_nacimiento", nullable = false)
    private LocalDate fechaNacimiento;

    public UsuarioEntity() {
    }

    public UsuarioEntity(
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