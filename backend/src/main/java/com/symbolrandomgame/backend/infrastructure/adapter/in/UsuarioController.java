package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.application.port.in.UsuarioUseCase;
import com.symbolrandomgame.backend.application.service.NombreUsuarioDuplicadoException;
import com.symbolrandomgame.backend.domain.model.Usuario;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioUseCase usuarioUseCase;

    public UsuarioController(UsuarioUseCase usuarioUseCase) {
        this.usuarioUseCase = usuarioUseCase;
    }

    @GetMapping
    public List<UsuarioResumenResponse> obtenerTodos() {
        return usuarioUseCase.obtenerTodos()
                .stream()
                .map(UsuarioResumenResponse::from)
                .toList();
    }

    @GetMapping("/{id}")
    public Usuario obtenerPorId(@PathVariable Integer id) {
        return usuarioUseCase.obtenerPorId(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Usuario crear(@RequestBody Usuario usuario) {
        try {
            return usuarioUseCase.crear(usuario);
        } catch (NombreUsuarioDuplicadoException exception) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "El nombre de usuario ya está registrado"
            );
        }
    }

    @PostMapping("/login")
    public Usuario iniciarSesion(@RequestBody LoginRequest request) {
        try {
            return usuarioUseCase.iniciarSesion(
                    request.nombreUso(),
                    request.contrasenaUs()
            );
        } catch (RuntimeException e) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Usuario o contraseña incorrectos"
            );
        }
    }

    @PutMapping("/{id}")
    public Usuario actualizar(
            @PathVariable Integer id,
            @RequestBody Usuario usuario
    ) {
        return usuarioUseCase.actualizar(id, usuario);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void eliminar(
            @PathVariable Integer id,
            @RequestBody EliminarCuentaRequest request
    ) {
        if (request == null || request.contrasenaUs() == null
                || request.contrasenaUs().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La contraseña es obligatoria"
            );
        }
        try {
            usuarioUseCase.eliminar(id, request.contrasenaUs());
        } catch (SecurityException exception) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "La contraseña no es correcta"
            );
        }
    }

    public record LoginRequest(
            String nombreUso,
            String contrasenaUs
    ) {}

    public record EliminarCuentaRequest(String contrasenaUs) {}
}