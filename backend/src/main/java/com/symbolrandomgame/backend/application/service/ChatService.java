package com.symbolrandomgame.backend.application.service;

import com.symbolrandomgame.backend.application.model.MensajeResponse;

import com.symbolrandomgame.backend.application.port.in.ChatUseCase;
import com.symbolrandomgame.backend.application.port.out.ChatOperationsPort;
import com.symbolrandomgame.backend.application.exception.UseCaseException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChatService implements ChatUseCase {
    private final ChatOperationsPort operationsPort;

    public ChatService(ChatOperationsPort operationsPort) {
        this.operationsPort = operationsPort;
    }

    @Override
    @Transactional
    public java.util.List<MensajeResponse> obtener(int idUsuario, int idAmigo) {
        validarAmistad(idUsuario, idAmigo);
        var messages = operationsPort.mensajes(idUsuario, idAmigo);
        long ultimo = messages.stream().filter(message -> message.idEmisor() == idAmigo)
                .mapToLong(MensajeResponse::idMensaje).max().orElse(0);
        operationsPort.marcarVistos(idUsuario, idAmigo, ultimo);
        return messages;
    }

    @Override
    @Transactional
    public MensajeResponse enviar(int idUsuario, int idAmigo, String contenido) {
        validarAmistad(idUsuario, idAmigo);
        if (contenido == null || contenido.trim().isEmpty()
                || contenido.trim().length() > 1000) {
            throw new UseCaseException(
                    400, "El mensaje debe tener entre 1 y 1000 caracteres"
            );
        }
        return operationsPort.guardar(idUsuario, idAmigo, contenido.trim());
    }

    private void validarAmistad(int idUsuario, int idAmigo) {
        if (idUsuario == idAmigo) {
            throw new UseCaseException(400, "No puedes abrir un chat contigo mismo");
        }
        if (!operationsPort.amistadAceptada(idUsuario, idAmigo)) {
            throw new UseCaseException(
                    403, "Solo puedes chatear con una amistad aceptada"
            );
        }
    }
}
