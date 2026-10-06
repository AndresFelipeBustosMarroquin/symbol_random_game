package com.symbolrandomgame.backend.infrastructure.adapter.in;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.sql.Timestamp;
import java.util.List;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/chats/{idAmigo}/mensajes")
public class ChatController {

    private final JdbcTemplate jdbcTemplate;

    public ChatController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public List<MensajeResponse> obtener(
            @PathVariable int idUsuario,
            @PathVariable int idAmigo
    ) {
        validarAmistad(idUsuario, idAmigo);
        return jdbcTemplate.query(
                """
                SELECT m.id_mensaje, m.id_emisor, u.nombre_uso AS emisor,
                       m.contenido, m.fecha_envio
                FROM chat_mensaje m
                JOIN usuario u ON u.id_usuario = m.id_emisor
                WHERE (m.id_emisor = ? AND m.id_receptor = ?)
                   OR (m.id_emisor = ? AND m.id_receptor = ?)
                ORDER BY m.fecha_envio, m.id_mensaje
                """,
                (rs, row) -> new MensajeResponse(
                        rs.getLong("id_mensaje"),
                        rs.getInt("id_emisor"),
                        rs.getString("emisor"),
                        rs.getString("contenido"),
                        rs.getTimestamp("fecha_envio")
                ),
                idUsuario, idAmigo, idAmigo, idUsuario
        );
    }

    @PostMapping
    @Transactional
    public MensajeResponse enviar(
            @PathVariable int idUsuario,
            @PathVariable int idAmigo,
            @RequestBody EnviarMensajeRequest request
    ) {
        validarAmistad(idUsuario, idAmigo);
        if (request == null || request.contenido() == null
                || request.contenido().trim().isEmpty()
                || request.contenido().trim().length() > 1000) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El mensaje debe tener entre 1 y 1000 caracteres"
            );
        }
        var rows = jdbcTemplate.query(
                """
                INSERT INTO chat_mensaje (id_emisor, id_receptor, contenido)
                VALUES (?, ?, ?)
                RETURNING id_mensaje, id_emisor, contenido, fecha_envio
                """,
                (rs, row) -> new MensajeResponse(
                        rs.getLong("id_mensaje"),
                        rs.getInt("id_emisor"),
                        "",
                        rs.getString("contenido"),
                        rs.getTimestamp("fecha_envio")
                ),
                idUsuario,
                idAmigo,
                request.contenido().trim()
        );
        var saved = rows.get(0);
        String author = jdbcTemplate.queryForObject(
                "SELECT nombre_uso FROM usuario WHERE id_usuario = ?",
                String.class,
                idUsuario
        );
        return new MensajeResponse(
                saved.idMensaje(),
                saved.idEmisor(),
                author,
                saved.contenido(),
                saved.fechaEnvio()
        );
    }

    private void validarAmistad(int idUsuario, int idAmigo) {
        if (idUsuario == idAmigo) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "No puedes abrir un chat contigo mismo"
            );
        }
        Integer friendship = jdbcTemplate.query(
                """
                SELECT 1 FROM amistad
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                  AND estado = 'ACEPTADA'
                """,
                rs -> rs.next() ? 1 : null,
                Math.min(idUsuario, idAmigo),
                Math.max(idUsuario, idAmigo)
        );
        if (friendship == null) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo puedes chatear con una amistad aceptada"
            );
        }
    }

    public record EnviarMensajeRequest(String contenido) {}

    public record MensajeResponse(
            long idMensaje,
            int idEmisor,
            String emisor,
            String contenido,
            Timestamp fechaEnvio
    ) {}
}
