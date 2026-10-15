package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.model.MensajeResponse;
import com.symbolrandomgame.backend.application.port.out.ChatOperationsPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ChatPersistenceAdapter implements ChatOperationsPort {
    private final JdbcTemplate jdbcTemplate;

    public ChatPersistenceAdapter(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public boolean amistadAceptada(int idUsuario, int idAmigo) {
        return Boolean.TRUE.equals(jdbcTemplate.query(
                """
                SELECT EXISTS (
                    SELECT 1 FROM amistad
                    WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                      AND estado = 'ACEPTADA'
                )
                """,
                rs -> rs.next() && rs.getBoolean(1),
                Math.min(idUsuario, idAmigo), Math.max(idUsuario, idAmigo)
        ));
    }

    @Override
    public List<MensajeResponse> mensajes(int idUsuario, int idAmigo) {
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
                        rs.getLong("id_mensaje"), rs.getInt("id_emisor"),
                        rs.getString("emisor"), rs.getString("contenido"),
                        rs.getTimestamp("fecha_envio")
                ),
                idUsuario, idAmigo, idAmigo, idUsuario
        );
    }

    @Override
    public void marcarVistos(int idUsuario, int idAmigo, long ultimoMensaje) {
        jdbcTemplate.update(
                """
                INSERT INTO chat_lectura (
                    id_usuario, id_amigo, ultimo_mensaje_visto, fecha_actualizacion
                ) VALUES (?, ?, ?, CURRENT_TIMESTAMP)
                ON CONFLICT (id_usuario, id_amigo) DO UPDATE
                SET ultimo_mensaje_visto = GREATEST(
                        chat_lectura.ultimo_mensaje_visto,
                        EXCLUDED.ultimo_mensaje_visto
                    ),
                    fecha_actualizacion = CURRENT_TIMESTAMP
                """,
                idUsuario, idAmigo, ultimoMensaje
        );
    }

    @Override
    public MensajeResponse guardar(int idUsuario, int idAmigo, String contenido) {
        List<MensajeResponse> saved = jdbcTemplate.query(
                """
                INSERT INTO chat_mensaje (id_emisor, id_receptor, contenido)
                VALUES (?, ?, ?)
                RETURNING id_mensaje, id_emisor, contenido, fecha_envio
                """,
                (rs, row) -> new MensajeResponse(
                        rs.getLong("id_mensaje"), rs.getInt("id_emisor"), "",
                        rs.getString("contenido"), rs.getTimestamp("fecha_envio")
                ),
                idUsuario, idAmigo, contenido
        );
        MensajeResponse message = saved.get(0);
        String author = jdbcTemplate.queryForObject(
                "SELECT nombre_uso FROM usuario WHERE id_usuario = ?",
                String.class, idUsuario
        );
        return new MensajeResponse(
                message.idMensaje(), message.idEmisor(), author,
                message.contenido(), message.fechaEnvio()
        );
    }
}
