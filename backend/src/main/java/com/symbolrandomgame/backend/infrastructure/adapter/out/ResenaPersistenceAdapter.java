package com.symbolrandomgame.backend.infrastructure.adapter.out;

import com.symbolrandomgame.backend.application.model.GuardarResenaCommand;
import com.symbolrandomgame.backend.application.model.ResenaResponse;
import com.symbolrandomgame.backend.application.port.out.ResenaOperationsPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ResenaPersistenceAdapter implements ResenaOperationsPort {
    private final JdbcTemplate jdbcTemplate;

    public ResenaPersistenceAdapter(JdbcTemplate jdbcTemplate) {
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
    public List<ResenaResponse> obtener(int idPerfil) {
        return jdbcTemplate.query(
                """
                SELECT r.id_autor, u.nombre_uso AS autor, u.avatar,
                       r.contenido, r.fecha_creacion
                FROM resena_perfil r
                JOIN usuario u ON u.id_usuario = r.id_autor
                WHERE r.id_perfil = ?
                ORDER BY r.fecha_creacion DESC, r.id_resena DESC
                """,
                (rs, row) -> new ResenaResponse(
                        rs.getInt("id_autor"), rs.getString("autor"),
                        rs.getString("avatar"), rs.getString("contenido"),
                        rs.getTimestamp("fecha_creacion")
                ),
                idPerfil
        );
    }

    @Override
    public ResenaResponse guardar(int idPerfil, GuardarResenaCommand request) {
        List<SavedReview> rows = jdbcTemplate.query(
                """
                INSERT INTO resena_perfil (id_autor, id_perfil, contenido)
                VALUES (?, ?, ?)
                ON CONFLICT (id_autor, id_perfil)
                DO UPDATE SET contenido = EXCLUDED.contenido,
                              fecha_creacion = CURRENT_TIMESTAMP
                RETURNING id_autor, contenido, fecha_creacion
                """,
                (rs, row) -> new SavedReview(
                        rs.getInt("id_autor"), rs.getString("contenido"),
                        rs.getTimestamp("fecha_creacion")
                ),
                request.idAutor(), idPerfil, request.contenido()
        );
        SavedReview saved = rows.get(0);
        return jdbcTemplate.queryForObject(
                """
                SELECT nombre_uso, avatar FROM usuario WHERE id_usuario = ?
                """,
                (rs, row) -> new ResenaResponse(
                        saved.authorId(), rs.getString("nombre_uso"),
                        rs.getString("avatar"), saved.content(), saved.createdAt()
                ),
                saved.authorId()
        );
    }

    private record SavedReview(
            int authorId,
            String content,
            java.sql.Timestamp createdAt
    ) {}
}
