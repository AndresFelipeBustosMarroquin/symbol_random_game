package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.port.in.UsuarioUseCase;
import com.symbolrandomgame.backend.application.port.out.UsuarioRepositoryPort;
import com.symbolrandomgame.backend.domain.model.Usuario;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UsuarioService implements UsuarioUseCase {

    private final UsuarioRepositoryPort usuarioRepositoryPort;

    public UsuarioService(
            UsuarioRepositoryPort usuarioRepositoryPort
    ) {
        this.usuarioRepositoryPort = usuarioRepositoryPort;
    }

    @Override
    public List<Usuario> obtenerTodos() {
        return usuarioRepositoryPort.obtenerTodos();
    }

    @Override
    public Usuario obtenerPorId(Integer id) {
        return usuarioRepositoryPort.obtenerPorId(id)
                .orElseThrow(
                        () -> new RuntimeException(
                                "Usuario no encontrado"
                        )
                );
    }

    @Override
    public Usuario crear(Usuario usuario) {
        if (usuarioRepositoryPort
                .obtenerPorNombreUso(usuario.getNombreUso())
                .isPresent()) {

            throw new RuntimeException(
                    "El nombre de usuario ya está registrado"
            );
        }

        return usuarioRepositoryPort.guardar(usuario);
    }

    @Override
    public Usuario iniciarSesion(
            String nombreUso,
            String contrasena
    ) {
        Usuario usuario = usuarioRepositoryPort
                .obtenerPorNombreUso(nombreUso)
                .orElseThrow(
                        () -> new RuntimeException(
                                "Usuario o contraseña incorrectos"
                        )
                );

        if (!usuario.getContrasenaUs().equals(contrasena)) {
            throw new RuntimeException(
                    "Usuario o contraseña incorrectos"
            );
        }

        return usuario;
    }

    @Override
    public Usuario actualizar(
            Integer id,
            Usuario usuario
    ) {
        Usuario existente = obtenerPorId(id);

        existente.setNombreUso(usuario.getNombreUso());
        existente.setContrasenaUs(usuario.getContrasenaUs());
        existente.setFechaNacimiento(
                usuario.getFechaNacimiento()
        );

        return usuarioRepositoryPort.guardar(existente);
    }

    @Override
    public void eliminar(Integer id, String contrasena) {
        Usuario usuario = obtenerPorId(id);
        if (!usuario.getContrasenaUs().equals(contrasena)) {
            throw new SecurityException("La contraseña no es correcta");
        }
        usuarioRepositoryPort.eliminar(id);
    }
}