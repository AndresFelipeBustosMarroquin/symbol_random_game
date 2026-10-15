package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.port.in.ChatUseCase;
import com.symbolrandomgame.backend.application.model.MensajeResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/chats/{idAmigo}/mensajes")
public class ChatController {
    private final ChatUseCase chatUseCase;

    public ChatController(ChatUseCase chatUseCase) {
        this.chatUseCase = chatUseCase;
    }

    @GetMapping
    public List<MensajeResponse> obtener(
            @PathVariable int idUsuario,
            @PathVariable int idAmigo
    ) {
        return ControllerErrors.translate(() -> chatUseCase.obtener(idUsuario, idAmigo));
    }

    @PostMapping
    public MensajeResponse enviar(
            @PathVariable int idUsuario,
            @PathVariable int idAmigo,
            @RequestBody EnviarMensajeRequest request
    ) {
        return ControllerErrors.translate(() -> chatUseCase.enviar(
                idUsuario, idAmigo, request == null ? null : request.contenido()
        ));
    }

    public record EnviarMensajeRequest(String contenido) {}
}
