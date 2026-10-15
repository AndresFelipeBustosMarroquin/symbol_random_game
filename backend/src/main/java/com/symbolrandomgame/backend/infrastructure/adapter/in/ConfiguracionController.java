package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.model.ConfiguracionCommand;
import com.symbolrandomgame.backend.application.model.ConfiguracionResponse;
import com.symbolrandomgame.backend.application.port.in.ConfiguracionUseCase;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/configuracion")
public class ConfiguracionController {
    private final ConfiguracionUseCase configuracionUseCase;

    public ConfiguracionController(ConfiguracionUseCase configuracionUseCase) {
        this.configuracionUseCase = configuracionUseCase;
    }

    @GetMapping
    public ConfiguracionResponse obtener(@PathVariable int idUsuario) {
        return ControllerErrors.translate(() -> configuracionUseCase.obtener(idUsuario));
    }

    @PutMapping
    public ConfiguracionResponse guardar(
            @PathVariable int idUsuario,
            @RequestBody ConfiguracionRequest request
    ) {
        ConfiguracionCommand command = request == null
                ? null
                : new ConfiguracionCommand(
                        request.incremento(),
                        request.vidas(),
                        request.tiempo(),
                        request.sonido(),
                        request.paleta(),
                        request.volumen(),
                        request.fuente()
                );
        return ControllerErrors.translate(
                () -> configuracionUseCase.guardar(idUsuario, command)
        );
    }
}
