package com.symbolrandomgame.backend.application.port.in;

import com.symbolrandomgame.backend.domain.model.Usuario;

import java.util.List;

public interface UsuarioUseCase {

    List<Usuario> obtenerTodos();

    Usuario obtenerPorId(Integer id);

    Usuario crear(Usuario usuario);

    Usuario iniciarSesion(
            String nombreUso,
            String contrasena
    );

    Usuario actualizar(
            Integer id,
            Usuario usuario
    );

    void eliminar(Integer id, String contrasena);
}