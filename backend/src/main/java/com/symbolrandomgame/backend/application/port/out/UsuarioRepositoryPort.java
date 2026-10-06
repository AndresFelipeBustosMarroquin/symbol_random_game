package com.symbolrandomgame.backend.application.port.out;

import com.symbolrandomgame.backend.domain.model.Usuario;

import java.util.List;
import java.util.Optional;

public interface UsuarioRepositoryPort {

    List<Usuario> obtenerTodos();

    Optional<Usuario> obtenerPorId(Integer id);

    Optional<Usuario> obtenerPorNombreUso(String nombreUso);

    Usuario guardar(Usuario usuario);

    void eliminar(Integer id);
}