package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.model.AmistadRegistro;
import com.symbolrandomgame.backend.application.model.PersonaAmistad;
import com.symbolrandomgame.backend.application.port.out.AmistadOperationsPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class AmistadPersistenceAdapter implements AmistadOperationsPort {
    private final JdbcTemplate jdbcTemplate;

    public AmistadPersistenceAdapter(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public boolean usuarioExiste(int idUsuario) {
        return Boolean.TRUE.equals(jdbcTemplate.query(
                "SELECT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = ?)",
                rs -> rs.next() && rs.getBoolean(1), idUsuario
        ));
    }

    @Override
    public List<PersonaAmistad> amigos(int idUsuario) {
        return jdbcTemplate.query(
                """
                SELECT u.id_usuario, u.nombre_uso, u.avatar,
                       COUNT(m.id_mensaje) AS mensajes_no_vistos
                FROM amistad a
                JOIN usuario u ON u.id_usuario = CASE
                    WHEN a.id_usuario_menor = ? THEN a.id_usuario_mayor
                    ELSE a.id_usuario_menor
                END
                LEFT JOIN chat_lectura l
                  ON l.id_usuario = ? AND l.id_amigo = u.id_usuario
                LEFT JOIN chat_mensaje m
                  ON m.id_emisor = u.id_usuario
                 AND m.id_receptor = ?
                 AND m.id_mensaje > COALESCE(l.ultimo_mensaje_visto, 0)
                WHERE (a.id_usuario_menor = ? OR a.id_usuario_mayor = ?)
                  AND a.estado = 'ACEPTADA'
                GROUP BY u.id_usuario, u.nombre_uso, u.avatar
                ORDER BY lower(u.nombre_uso)
                """,
                (rs, row) -> new PersonaAmistad(
                        rs.getInt("id_usuario"), rs.getString("nombre_uso"),
                        rs.getString("avatar"), rs.getInt("mensajes_no_vistos")
                ),
                idUsuario, idUsuario, idUsuario, idUsuario, idUsuario
        );
    }

    @Override
    public List<PersonaAmistad> solicitudes(int idUsuario, boolean enviadas) {
        String condition = enviadas
                ? "a.id_solicitante = ?" : "a.id_solicitante <> ?";
        return jdbcTemplate.query(
                """
                SELECT u.id_usuario, u.nombre_uso, u.avatar, 0 AS mensajes_no_vistos
                FROM amistad a
                JOIN usuario u ON u.id_usuario = CASE
                    WHEN a.id_usuario_menor = ? THEN a.id_usuario_mayor
                    ELSE a.id_usuario_menor
                END
                WHERE (a.id_usuario_menor = ? OR a.id_usuario_mayor = ?)
                  AND a.estado = 'PENDIENTE'
                  AND %s
                ORDER BY a.fecha_actualizacion DESC
                """.formatted(condition),
                (rs, row) -> new PersonaAmistad(
                        rs.getInt("id_usuario"), rs.getString("nombre_uso"),
                        rs.getString("avatar"), rs.getInt("mensajes_no_vistos")
                ),
                idUsuario, idUsuario, idUsuario, idUsuario
        );
    }

    @Override
    public AmistadRegistro estado(int idUsuario, int idOtro) {
        return jdbcTemplate.query(
                """
                SELECT estado, id_solicitante
                FROM amistad
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                """,
                rs -> rs.next()
                        ? new AmistadRegistro(rs.getString("estado"), rs.getInt("id_solicitante"))
                        : null,
                Math.min(idUsuario, idOtro), Math.max(idUsuario, idOtro)
        );
    }

    @Override
    public int insertarSolicitud(int idUsuario, int idDestino) {
        return jdbcTemplate.update(
                """
                INSERT INTO amistad (
                    id_usuario_menor, id_usuario_mayor, id_solicitante, estado
                ) VALUES (?, ?, ?, 'PENDIENTE')
                ON CONFLICT (id_usuario_menor, id_usuario_mayor) DO NOTHING
                """,
                Math.min(idUsuario, idDestino), Math.max(idUsuario, idDestino), idUsuario
        );
    }

    @Override
    public int aceptarSolicitud(int idUsuario, int idOtro) {
        return jdbcTemplate.update(
                """
                UPDATE amistad
                SET estado = 'ACEPTADA', fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                  AND id_solicitante = ? AND estado = 'PENDIENTE'
                """,
                Math.min(idUsuario, idOtro), Math.max(idUsuario, idOtro), idOtro
        );
    }

    @Override
    public void eliminar(int idUsuario, int idOtro) {
        jdbcTemplate.update(
                """
                DELETE FROM amistad
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                """,
                Math.min(idUsuario, idOtro), Math.max(idUsuario, idOtro)
        );
    }
}
