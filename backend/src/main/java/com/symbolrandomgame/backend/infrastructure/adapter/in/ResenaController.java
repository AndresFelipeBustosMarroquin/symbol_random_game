package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.model.GuardarResenaCommand;
import com.symbolrandomgame.backend.application.model.ResenaResponse;
import com.symbolrandomgame.backend.application.port.in.ResenaUseCase;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios/{idPerfil}/resenas")
public class ResenaController {
    private final ResenaUseCase resenaUseCase;

    public ResenaController(ResenaUseCase resenaUseCase) {
        this.resenaUseCase = resenaUseCase;
    }

    @GetMapping
    public List<ResenaResponse> obtener(
            @PathVariable int idPerfil
    ) {
        return ControllerErrors.translate(() -> resenaUseCase.obtener(idPerfil));
    }

    @PostMapping
    public ResenaResponse guardar(
            @PathVariable int idPerfil,
            @RequestBody GuardarResenaRequest request
    ) {
        GuardarResenaCommand command = request == null
                ? null
                : new GuardarResenaCommand(
                        request.idAutor(),
                        request.contenido()
                );
        return ControllerErrors.translate(() -> resenaUseCase.guardar(idPerfil, command));
    }

    public record GuardarResenaRequest(Integer idAutor, String contenido) {}
}
