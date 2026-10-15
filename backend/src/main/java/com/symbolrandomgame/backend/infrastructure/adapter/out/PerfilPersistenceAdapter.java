package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.model.ActualizarPerfilCommand;
import com.symbolrandomgame.backend.application.model.PerfilResponse;
import com.symbolrandomgame.backend.application.model.PerfilUpdateResult;
import com.symbolrandomgame.backend.application.port.out.PerfilOperationsPort;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class PerfilPersistenceAdapter implements PerfilOperationsPort {
    private final JdbcTemplate jdbcTemplate;

    public PerfilPersistenceAdapter(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public boolean usuarioExiste(int idUsuario) {
        return Boolean.TRUE.equals(jdbcTemplate.query(
                "SELECT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = ?)",
                rs -> rs.next() && rs.getBoolean(1),
                idUsuario
        ));
    }

    @Override
    public PerfilResponse obtener(int idUsuario) {
        List<PerfilResponse> rows = jdbcTemplate.query(
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
                (rs, row) -> new PerfilResponse(
                        rs.getInt("id_usuario"), rs.getString("nombre_uso"),
                        rs.getDate("fecha_nacimiento").toLocalDate(),
                        rs.getString("descripcion"), rs.getString("avatar"),
                        rs.getInt("partidas"), rs.getInt("mejor_puntuacion"),
                        rs.getLong("puntos_totales"), rs.getInt("partidas_numeros"),
                        rs.getInt("mejor_numeros"), rs.getInt("partidas_caracteres"),
                        rs.getInt("mejor_caracteres"), rs.getInt("partidas_simbolos"),
                        rs.getInt("mejor_simbolos"), rs.getInt("partidas_operaciones"),
                        rs.getInt("mejor_operaciones")
                ),
                idUsuario
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    @Override
    public PerfilUpdateResult actualizar(int idUsuario, ActualizarPerfilCommand request) {
        try {
            int changed = jdbcTemplate.update(
                    """
                    UPDATE usuario
                    SET nombre_uso = ?, fecha_nacimiento = ?,
                        descripcion = ?, avatar = ?
                    WHERE id_usuario = ?
                    """,
                    request.nombreUso().trim(), request.fechaNacimiento(),
                    request.descripcion().trim(), request.avatar(), idUsuario
            );
            return changed == 0
                    ? PerfilUpdateResult.USER_NOT_FOUND
                    : PerfilUpdateResult.UPDATED;
        } catch (DuplicateKeyException exception) {
            return PerfilUpdateResult.DUPLICATE_NAME;
        }
    }
}
