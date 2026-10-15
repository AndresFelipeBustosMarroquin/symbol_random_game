package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.model.GuardarPuntuacionCommand;
import com.symbolrandomgame.backend.application.model.ModoData;
import com.symbolrandomgame.backend.application.model.NivelData;
import com.symbolrandomgame.backend.application.model.PuntuacionData;
import com.symbolrandomgame.backend.application.port.out.PuntuacionOperationsPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class PuntuacionPersistenceAdapter implements PuntuacionOperationsPort {
    private static final String CONSULTA_PUNTUACIONES = """
            SELECT u.id_usuario, p.id_puntuacion, u.nombre_uso,
                   m.nombre_modo, p.digitos, p.vidas_pun, p.tiempo_pregunta,
                   p.tiempo_total, p.resultado, u.fecha_nacimiento
            FROM puntuacion p
            JOIN usuario u ON u.id_usuario = p.id_usuario
            JOIN partida pa ON pa.id_partida = p.id_partida
            JOIN modo_juego m ON m.id_modo = pa.id_modo
            ORDER BY p.resultado DESC, p.id_puntuacion ASC
            """;

    private final JdbcTemplate jdbcTemplate;

    public PuntuacionPersistenceAdapter(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public List<PuntuacionData> obtenerTodas() {
        return jdbcTemplate.query(
                CONSULTA_PUNTUACIONES,
                (rs, row) -> new PuntuacionData(
                        rs.getInt("id_puntuacion"), rs.getInt("id_usuario"),
                        rs.getString("nombre_uso"), rs.getString("nombre_modo"),
                        rs.getInt("digitos"), rs.getInt("vidas_pun"),
                        rs.getInt("tiempo_pregunta"), rs.getInt("tiempo_total"),
                        rs.getInt("resultado"), rs.getDate("fecha_nacimiento").toLocalDate()
                )
        );
    }

    @Override
    public boolean usuarioExiste(int idUsuario) {
        return Boolean.TRUE.equals(jdbcTemplate.query(
                "SELECT EXISTS (SELECT 1 FROM usuario WHERE id_usuario = ?)",
                rs -> rs.next() && rs.getBoolean(1), idUsuario
        ));
    }

    @Override
    public boolean puntuacionExiste(int idPuntuacion) {
        return Boolean.TRUE.equals(jdbcTemplate.query(
                "SELECT EXISTS (SELECT 1 FROM puntuacion WHERE id_puntuacion = ?)",
                rs -> rs.next() && rs.getBoolean(1), idPuntuacion
        ));
    }

    @Override
    public int eliminarPartidaPropia(int idPuntuacion, int idUsuario) {
        return jdbcTemplate.update(
                """
                DELETE FROM partida
                WHERE id_partida = (
                    SELECT id_partida FROM puntuacion
                    WHERE id_puntuacion = ? AND id_usuario = ?
                )
                """,
                idPuntuacion, idUsuario
        );
    }

    @Override
    public List<ModoData> modos() {
        return jdbcTemplate.query(
                "SELECT id_modo, nombre_modo FROM modo_juego",
                (rs, row) -> new ModoData(rs.getInt("id_modo"), rs.getString("nombre_modo"))
        );
    }

    @Override
    public Integer crearModo(String nombre) {
        return jdbcTemplate.queryForObject(
                """
                INSERT INTO modo_juego (nombre_modo, descripcion)
                VALUES (?, ?)
                RETURNING id_modo
                """,
                Integer.class, nombre, "Modo de juego"
        );
    }

    @Override
    public NivelData guardarNivel(
            int modoId, String nombre, int digitos, int tiempo, int vidas
    ) {
        List<NivelData> levels = jdbcTemplate.query(
                """
                INSERT INTO nivel (
                    id_modo, nombre_nivel, digitos_base, tiempo_base, vidas_base
                )
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT (id_modo, digitos_base, tiempo_base, vidas_base)
                DO UPDATE SET nombre_nivel = EXCLUDED.nombre_nivel
                RETURNING id_nivel, nombre_nivel
                """,
                (rs, row) -> new NivelData(rs.getInt("id_nivel"), rs.getString("nombre_nivel")),
                modoId, nombre, digitos, tiempo, vidas
        );
        return levels.isEmpty() ? null : levels.get(0);
    }

    @Override
    public int crearPartida(
            int usuarioId, int modoId, int nivelId,
            LocalDateTime inicio, LocalDateTime fin, int resultado
    ) {
        return jdbcTemplate.queryForObject(
                """
                INSERT INTO partida (
                    id_usuario, id_modo, id_nivel, fecha_inicio, fecha_fin, resultado
                )
                VALUES (?, ?, ?, ?, ?, ?)
                RETURNING id_partida
                """,
                Integer.class, usuarioId, modoId, nivelId, inicio, fin, resultado
        );
    }

    @Override
    public void guardarPuntuacion(
            NivelData nivel,
            GuardarPuntuacionCommand request,
            int partidaId
    ) {
        jdbcTemplate.update(
                """
                INSERT INTO puntuacion (
                    nivel, digitos, vidas_pun, tiempo_pregunta, tiempo_total,
                    resultado, id_usuario, id_partida
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                nivel.nombre(), request.digitos(), request.vidas(),
                request.tiempoPregunta(), request.tiempoTotal(), request.resultado(),
                request.idUsuario(), partidaId
        );
    }
}
