package com.symbolrandomgame.backend.infrastructure.adapter.in;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/perfil")
public class PerfilController {

    private static final List<String> AVATARES = List.of(
            "astronauta", "zorro", "gato", "ajolote", "dragon",
            "robot", "tigre", "panda", "unicornio", "pulpo"
    );

    private final JdbcTemplate jdbcTemplate;

    public PerfilController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public PerfilResponse obtener(@PathVariable int idUsuario) {
        var profiles = jdbcTemplate.query(
                """
                SELECT u.id_usuario, u.nombre_uso, u.fecha_nacimiento,
                       u.descripcion, u.avatar,
                       COUNT(p.id_puntuacion) AS partidas,
                       COALESCE(MAX(p.resultado), 0) AS mejor_puntuacion,
                       COALESCE(SUM(p.resultado), 0) AS puntos_totales,
                       COUNT(p.id_puntuacion) FILTER (
                           WHERE upper(m.nombre_modo) IN ('NÚMEROS', 'NUMEROS')
                       ) AS partidas_numeros,
                       COALESCE(MAX(p.resultado) FILTER (
                           WHERE upper(m.nombre_modo) IN ('NÚMEROS', 'NUMEROS')
                       ), 0) AS mejor_numeros,
                       COUNT(p.id_puntuacion) FILTER (
                           WHERE upper(m.nombre_modo) = 'CARACTERES'
                       ) AS partidas_caracteres,
                       COALESCE(MAX(p.resultado) FILTER (
                           WHERE upper(m.nombre_modo) = 'CARACTERES'
                       ), 0) AS mejor_caracteres,
                       COUNT(p.id_puntuacion) FILTER (
                           WHERE upper(m.nombre_modo) IN ('SÍMBOLOS', 'SIMBOLOS')
                       ) AS partidas_simbolos,
                       COALESCE(MAX(p.resultado) FILTER (
                           WHERE upper(m.nombre_modo) IN ('SÍMBOLOS', 'SIMBOLOS')
                       ), 0) AS mejor_simbolos,
                       COUNT(p.id_puntuacion) FILTER (
                           WHERE upper(m.nombre_modo) = 'OPERACIONES'
                       ) AS partidas_operaciones,
                       COALESCE(MAX(p.resultado) FILTER (
                           WHERE upper(m.nombre_modo) = 'OPERACIONES'
                       ), 0) AS mejor_operaciones
                FROM usuario u
                LEFT JOIN puntuacion p ON p.id_usuario = u.id_usuario
                LEFT JOIN partida pa ON pa.id_partida = p.id_partida
                LEFT JOIN modo_juego m ON m.id_modo = pa.id_modo
                WHERE u.id_usuario = ?
                GROUP BY u.id_usuario
                """,
                (resultSet, rowNumber) -> new PerfilResponse(
                        resultSet.getInt("id_usuario"),
                        resultSet.getString("nombre_uso"),
                        resultSet.getDate("fecha_nacimiento").toLocalDate(),
                        resultSet.getString("descripcion"),
                        resultSet.getString("avatar"),
                        resultSet.getInt("partidas"),
                        resultSet.getInt("mejor_puntuacion"),
                        resultSet.getLong("puntos_totales"),
                        resultSet.getInt("partidas_numeros"),
                        resultSet.getInt("mejor_numeros"),
                        resultSet.getInt("partidas_caracteres"),
                        resultSet.getInt("mejor_caracteres"),
                        resultSet.getInt("partidas_simbolos"),
                        resultSet.getInt("mejor_simbolos"),
                        resultSet.getInt("partidas_operaciones"),
                        resultSet.getInt("mejor_operaciones")
                ),
                idUsuario
        );
        if (profiles.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El usuario no existe");
        }
        return profiles.get(0);
    }

    @PutMapping
    public PerfilResponse actualizar(
            @PathVariable int idUsuario,
            @RequestBody ActualizarPerfilRequest request
    ) {
        validar(idUsuario, request);
        try {
            int updated = jdbcTemplate.update(
                    """
                    UPDATE usuario
                    SET nombre_uso = ?, fecha_nacimiento = ?,
                        descripcion = ?, avatar = ?
                    WHERE id_usuario = ?
                    """,
                    request.nombreUso().trim(),
                    request.fechaNacimiento(),
                    request.descripcion().trim(),
                    request.avatar(),
                    idUsuario
            );
            if (updated == 0) {
                throw new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El usuario no existe"
                );
            }
        } catch (DuplicateKeyException exception) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ese nombre de usuario ya está en uso"
            );
        }
        return obtener(idUsuario);
    }

    private void validar(int idUsuario, ActualizarPerfilRequest request) {
        if (request == null
                || request.nombreUso() == null
                || request.nombreUso().trim().length() < 3
                || request.nombreUso().trim().length() > 50
                || request.fechaNacimiento() == null
                || request.fechaNacimiento().isAfter(LocalDate.now())
                || request.descripcion() == null
                || request.descripcion().length() > 180
                || request.avatar() == null
                || !AVATARES.contains(request.avatar())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Los datos del perfil no son válidos"
            );
        }
        Integer exists = jdbcTemplate.query(
                "SELECT id_usuario FROM usuario WHERE id_usuario = ?",
                resultSet -> resultSet.next() ? resultSet.getInt(1) : null,
                idUsuario
        );
        if (exists == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "El usuario no existe"
            );
        }
    }

    public record ActualizarPerfilRequest(
            String nombreUso,
            LocalDate fechaNacimiento,
            String descripcion,
            String avatar
    ) {
    }

    public record PerfilResponse(
            int idUsuario,
            String nombreUso,
            LocalDate fechaNacimiento,
            String descripcion,
            String avatar,
            int partidas,
            int mejorPuntuacion,
            long puntosTotales,
            int partidasNumeros,
            int mejorNumeros,
            int partidasCaracteres,
            int mejorCaracteres,
            int partidasSimbolos,
            int mejorSimbolos,
            int partidasOperaciones,
            int mejorOperaciones
    ) {
    }
}
