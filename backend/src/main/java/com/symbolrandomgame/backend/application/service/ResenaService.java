package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.model.GuardarResenaCommand;
import com.symbolrandomgame.backend.application.model.ResenaResponse;
import com.symbolrandomgame.backend.application.port.in.ResenaUseCase;
import com.symbolrandomgame.backend.application.port.out.ResenaOperationsPort;
import com.symbolrandomgame.backend.application.exception.UseCaseException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ResenaService implements ResenaUseCase {
    private final ResenaOperationsPort operationsPort;

    public ResenaService(ResenaOperationsPort operationsPort) {
        this.operationsPort = operationsPort;
    }

    @Override
    public List<ResenaResponse> obtener(int idPerfil) {
        validarUsuario(idPerfil);
        return operationsPort.obtener(idPerfil);
    }

    @Override
    @Transactional
    public ResenaResponse guardar(int idPerfil, GuardarResenaCommand request) {
        if (request == null || request.idAutor() == null || request.idAutor() <= 0
                || request.contenido() == null || request.contenido().trim().isEmpty()
                || request.contenido().trim().length() > 500) {
            throw new UseCaseException(
                    400, "La reseña debe tener entre 1 y 500 caracteres"
            );
        }
        validarUsuario(idPerfil);
        validarUsuario(request.idAutor());
        if (idPerfil == request.idAutor()) {
            throw new UseCaseException(
                    400, "No puedes dejar una reseña en tu propio perfil"
            );
        }
        return operationsPort.guardar(
                idPerfil,
                new GuardarResenaCommand(request.idAutor(), request.contenido().trim())
        );
    }

    private void validarUsuario(int idUsuario) {
        if (!operationsPort.usuarioExiste(idUsuario)) {
            throw new UseCaseException(404, "El usuario no existe");
        }
    }
}
