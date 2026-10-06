package com.symbolrandomgame.backend.infrastructure.adapter.out;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UsuarioJpaRepository
        extends JpaRepository<UsuarioEntity, Integer> {

    boolean existsByNombreUso(String nombreUso);

    Optional<UsuarioEntity> findByNombreUso(String nombreUso);
}