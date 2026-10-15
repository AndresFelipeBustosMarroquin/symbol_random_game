package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.model.AmistadRegistro;
import com.symbolrandomgame.backend.application.model.AmistadesResponse;
import com.symbolrandomgame.backend.application.model.EstadoAmistadResponse;

import com.symbolrandomgame.backend.application.port.in.AmistadUseCase;
import com.symbolrandomgame.backend.application.port.out.AmistadOperationsPort;
import com.symbolrandomgame.backend.application.exception.UseCaseException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AmistadService implements AmistadUseCase {
    private final AmistadOperationsPort operationsPort;

    public AmistadService(AmistadOperationsPort operationsPort) {
        this.operationsPort = operationsPort;
    }

    @Override
    public AmistadesResponse obtener(int idUsuario) {
        validarUsuario(idUsuario);
        return new AmistadesResponse(
                operationsPort.amigos(idUsuario),
                operationsPort.solicitudes(idUsuario, false),
                operationsPort.solicitudes(idUsuario, true)
        );
    }

    @Override
    public EstadoAmistadResponse estado(int idUsuario, int idOtro) {
        validarPar(idUsuario, idOtro);
        AmistadRegistro registro = operationsPort.estado(idUsuario, idOtro);
        if (registro == null) return new EstadoAmistadResponse("NINGUNA", null);
        if ("ACEPTADA".equals(registro.estado())) {
            return new EstadoAmistadResponse("AMIGOS", null);
        }
        return new EstadoAmistadResponse(
                registro.idSolicitante() == idUsuario ? "ENVIADA" : "RECIBIDA",
                registro.idSolicitante()
        );
    }

    @Override
    @Transactional
    public EstadoAmistadResponse solicitar(int idUsuario, int idDestino) {
        validarPar(idUsuario, idDestino);
        if (operationsPort.insertarSolicitud(idUsuario, idDestino) == 0) {
            throw new UseCaseException(
                    409, "Ya existe una solicitud o amistad con este usuario"
            );
        }
        return new EstadoAmistadResponse("ENVIADA", idUsuario);
    }

    @Override
    @Transactional
    public EstadoAmistadResponse aceptar(int idUsuario, int idOtro) {
        validarPar(idUsuario, idOtro);
        if (operationsPort.aceptarSolicitud(idUsuario, idOtro) == 0) {
            throw new UseCaseException(
                    404, "No se encontró una solicitud pendiente de este usuario"
            );
        }
        return new EstadoAmistadResponse("AMIGOS", null);
    }

    @Override
    @Transactional
    public void eliminar(int idUsuario, int idOtro) {
        validarPar(idUsuario, idOtro);
        operationsPort.eliminar(idUsuario, idOtro);
    }

    private void validarPar(int idUsuario, int idOtro) {
        validarUsuario(idUsuario);
        validarUsuario(idOtro);
        if (idUsuario == idOtro) {
            throw new UseCaseException(400, "No puedes enviarte una solicitud de amistad");
        }
    }

    private void validarUsuario(int idUsuario) {
        if (!operationsPort.usuarioExiste(idUsuario)) {
            throw new UseCaseException(404, "El usuario no existe");
        }
    }
}
