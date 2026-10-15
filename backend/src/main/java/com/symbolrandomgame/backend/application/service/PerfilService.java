package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.model.ActualizarPerfilCommand;
import com.symbolrandomgame.backend.application.model.PerfilResponse;
import com.symbolrandomgame.backend.application.model.PerfilUpdateResult;
import com.symbolrandomgame.backend.application.port.in.PerfilUseCase;
import com.symbolrandomgame.backend.application.port.out.PerfilOperationsPort;
import com.symbolrandomgame.backend.application.exception.UseCaseException;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class PerfilService implements PerfilUseCase {
    private final PerfilOperationsPort operationsPort;

    public PerfilService(PerfilOperationsPort operationsPort) {
        this.operationsPort = operationsPort;
    }

    @Override
    public PerfilResponse obtener(int idUsuario) {
        PerfilResponse profile = operationsPort.obtener(idUsuario);
        if (profile == null) throw new UseCaseException(404, "El usuario no existe");
        return profile;
    }

    @Override
    public PerfilResponse actualizar(int idUsuario, ActualizarPerfilCommand request) {
        if (request == null || request.nombreUso() == null
                || request.nombreUso().trim().length() < 3
                || request.nombreUso().trim().length() > 50
                || request.fechaNacimiento() == null
                || request.fechaNacimiento().isAfter(LocalDate.now())
                || request.descripcion() == null || request.descripcion().length() > 180
                || request.avatar() == null || !AVATARES.contains(request.avatar())) {
            throw new UseCaseException(400, "Los datos del perfil no son válidos");
        }
        if (!operationsPort.usuarioExiste(idUsuario)) {
            throw new UseCaseException(404, "El usuario no existe");
        }
        PerfilUpdateResult result = operationsPort.actualizar(idUsuario, request);
        if (result == PerfilUpdateResult.USER_NOT_FOUND) {
            throw new UseCaseException(404, "El usuario no existe");
        }
        if (result == PerfilUpdateResult.DUPLICATE_NAME) {
            throw new UseCaseException(409, "Ese nombre de usuario ya está en uso");
        }
        return obtener(idUsuario);
    }

    private static final List<String> AVATARES = List.of(
            "astronauta", "zorro", "gato", "ajolote", "dragon",
            "robot", "tigre", "panda", "unicornio", "pulpo"
    );
}
