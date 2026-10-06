package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.port.out.UsuarioRepositoryPort;
import com.symbolrandomgame.backend.domain.model.Usuario;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertNull;

class UsuarioServiceTest {

    @Test
    void eliminaLaCuentaCuandoLaContrasenaEsCorrecta() {
        var repository = new FakeUsuarioRepository();
        var service = new UsuarioService(repository);

        service.eliminar(7, "clave-segura");

        assertEquals(7, repository.deletedUserId);
    }

    @Test
    void conservaLaCuentaCuandoLaContrasenaEsIncorrecta() {
        var repository = new FakeUsuarioRepository();
        var service = new UsuarioService(repository);

        assertThrows(
                SecurityException.class,
                () -> service.eliminar(7, "incorrecta")
        );

        assertNull(repository.deletedUserId);
    }

    private static final class FakeUsuarioRepository
            implements UsuarioRepositoryPort {

        private final Usuario usuario = new Usuario(
                7,
                "Jugador",
                "clave-segura",
                LocalDate.of(2000, 1, 1)
        );
        private Integer deletedUserId;

        @Override
        public List<Usuario> obtenerTodos() {
            return List.of(usuario);
        }

        @Override
        public Optional<Usuario> obtenerPorId(Integer id) {
            return id.equals(usuario.getIdUsuario())
                    ? Optional.of(usuario)
                    : Optional.empty();
        }

        @Override
        public Optional<Usuario> obtenerPorNombreUso(String nombreUso) {
            return usuario.getNombreUso().equals(nombreUso)
                    ? Optional.of(usuario)
                    : Optional.empty();
        }

        @Override
        public Usuario guardar(Usuario usuario) {
            return usuario;
        }

        @Override
        public void eliminar(Integer id) {
            deletedUserId = id;
        }
    }
}
