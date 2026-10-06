package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.port.out.UsuarioRepositoryPort;
import com.symbolrandomgame.backend.domain.model.Usuario;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
public class UsuarioPersistenceAdapter
        implements UsuarioRepositoryPort {

    private final UsuarioJpaRepository usuarioJpaRepository;

    public UsuarioPersistenceAdapter(
            UsuarioJpaRepository usuarioJpaRepository
    ) {
        this.usuarioJpaRepository = usuarioJpaRepository;
    }

    @Override
    public List<Usuario> obtenerTodos() {
        return usuarioJpaRepository
                .findAll()
                .stream()
                .map(this::toDomain)
                .toList();
    }

    @Override
    public Optional<Usuario> obtenerPorId(Integer id) {
        return usuarioJpaRepository
                .findById(id)
                .map(this::toDomain);
    }

    @Override
    public Optional<Usuario> obtenerPorNombreUso(
            String nombreUso
    ) {
        return usuarioJpaRepository
                .findByNombreUso(nombreUso)
                .map(this::toDomain);
    }

    @Override
    public Usuario guardar(Usuario usuario) {
        UsuarioEntity entity = toEntity(usuario);

        UsuarioEntity guardado =
                usuarioJpaRepository.save(entity);

        return toDomain(guardado);
    }

    @Override
    public void eliminar(Integer id) {
        usuarioJpaRepository.deleteById(id);
    }

    private Usuario toDomain(
            UsuarioEntity entity
    ) {
        return new Usuario(
                entity.getIdUsuario(),
                entity.getNombreUso(),
                entity.getContrasenaUs(),
                entity.getFechaNacimiento()
        );
    }

    private UsuarioEntity toEntity(
            Usuario usuario
    ) {
        return new UsuarioEntity(
                usuario.getIdUsuario(),
                usuario.getNombreUso(),
                usuario.getContrasenaUs(),
                usuario.getFechaNacimiento()
        );
    }
}