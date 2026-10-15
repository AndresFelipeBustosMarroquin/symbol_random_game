package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.model.ConfiguracionCommand;
import com.symbolrandomgame.backend.application.model.ConfiguracionData;
import com.symbolrandomgame.backend.application.model.PaletaData;
import com.symbolrandomgame.backend.application.port.out.ConfiguracionOperationsPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ConfiguracionPersistenceAdapter implements ConfiguracionOperationsPort {
    private final JdbcTemplate jdbcTemplate;

    public ConfiguracionPersistenceAdapter(JdbcTemplate jdbcTemplate) {
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
    public ConfiguracionData obtener(int idUsuario) {
        List<ConfiguracionData> rows = jdbcTemplate.query(
                """
                SELECT c.digitos_co, c.vidas_co, c.tiempo_co, c.sonido,
                       p.nombre AS paleta, c.volumen, c.fuente
                FROM configuraciones c
                JOIN paleta p ON p.id_paleta = c.id_paleta
                WHERE c.id_usuario = ?
                """,
                (rs, row) -> new ConfiguracionData(
                        rs.getInt("digitos_co"), rs.getInt("vidas_co"),
                        rs.getInt("tiempo_co"), rs.getInt("sonido"),
                        rs.getString("paleta"), rs.getDouble("volumen"),
                        rs.getInt("fuente")
                ),
                idUsuario
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    @Override
    public List<PaletaData> paletas() {
        return jdbcTemplate.query(
                "SELECT id_paleta, nombre FROM paleta",
                (rs, row) -> new PaletaData(rs.getInt("id_paleta"), rs.getString("nombre"))
        );
    }

    @Override
    public Integer avatarActual(int idUsuario) {
        return jdbcTemplate.query(
                "SELECT id_avatar FROM configuraciones WHERE id_usuario = ?",
                rs -> rs.next() ? rs.getInt(1) : null,
                idUsuario
        );
    }

    @Override
    public Integer avatarPredeterminado() {
        return jdbcTemplate.query(
                "SELECT id_avatar FROM avatar ORDER BY id_avatar LIMIT 1",
                rs -> rs.next() ? rs.getInt(1) : null
        );
    }

    @Override
    public void guardar(
            int idUsuario,
            ConfiguracionCommand request,
            int idPaleta,
            int idAvatar
    ) {
        jdbcTemplate.update(
                """
                INSERT INTO configuraciones (
                    sonido, vidas_co, digitos_co, id_paleta, id_avatar, id_usuario,
                    tiempo_co, volumen, fuente
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT (id_usuario) DO UPDATE SET
                    sonido = EXCLUDED.sonido,
                    vidas_co = EXCLUDED.vidas_co,
                    digitos_co = EXCLUDED.digitos_co,
                    id_paleta = EXCLUDED.id_paleta,
                    tiempo_co = EXCLUDED.tiempo_co,
                    volumen = EXCLUDED.volumen,
                    fuente = EXCLUDED.fuente
                """,
                request.sonido(), request.vidas(), request.incremento(),
                idPaleta, idAvatar, idUsuario, request.tiempo(),
                request.volumen(), request.fuente()
        );
    }
}
