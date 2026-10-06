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
@RequestMapping("/api/usuarios/{idPerfil}/resenas")
public class ResenaController {

    private final JdbcTemplate jdbcTemplate;

    public ResenaController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public List<ResenaResponse> obtener(@PathVariable int idPerfil) {
        validarUsuario(idPerfil);
        return jdbcTemplate.query(
                """
                SELECT r.id_autor, u.nombre_uso AS autor, u.avatar,
                       r.contenido, r.fecha_creacion
                FROM resena_perfil r
                JOIN usuario u ON u.id_usuario = r.id_autor
                WHERE r.id_perfil = ?
                ORDER BY r.fecha_creacion DESC, r.id_resena DESC
                """,
                (resultSet, rowNumber) -> new ResenaResponse(
                        resultSet.getInt("id_autor"),
                        resultSet.getString("autor"),
                        resultSet.getString("avatar"),
                        resultSet.getString("contenido"),
                        resultSet.getTimestamp("fecha_creacion")
                ),
                idPerfil
        );
    }

    @PostMapping
    @Transactional
    public ResenaResponse guardar(
            @PathVariable int idPerfil,
            @RequestBody GuardarResenaRequest request
    ) {
        if (request == null
                || request.idAutor() == null
                || request.idAutor() <= 0
                || request.contenido() == null
                || request.contenido().trim().isEmpty()
                || request.contenido().trim().length() > 500) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La reseña debe tener entre 1 y 500 caracteres"
            );
        }
        validarUsuario(idPerfil);
        validarUsuario(request.idAutor());
        if (idPerfil == request.idAutor()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "No puedes dejar una reseña en tu propio perfil"
            );
        }

        var saved = jdbcTemplate.query(
                """
                INSERT INTO resena_perfil (id_autor, id_perfil, contenido)
                VALUES (?, ?, ?)
                ON CONFLICT (id_autor, id_perfil)
                DO UPDATE SET contenido = EXCLUDED.contenido,
                              fecha_creacion = CURRENT_TIMESTAMP
                RETURNING id_autor, contenido, fecha_creacion
                """,
                (resultSet, rowNumber) -> new SavedReview(
                        resultSet.getInt("id_autor"),
                        resultSet.getString("contenido"),
                        resultSet.getTimestamp("fecha_creacion")
                ),
                request.idAutor(),
                idPerfil,
                request.contenido().trim()
        );
        var result = saved.get(0);
        String author = jdbcTemplate.queryForObject(
                "SELECT nombre_uso FROM usuario WHERE id_usuario = ?",
                String.class,
                result.authorId()
        );
        String avatar = jdbcTemplate.queryForObject(
                "SELECT avatar FROM usuario WHERE id_usuario = ?",
                String.class,
                result.authorId()
        );
        return new ResenaResponse(
                result.authorId(),
                author,
                avatar,
                result.content(),
                result.createdAt()
        );
    }

    private void validarUsuario(int idUsuario) {
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

    public record GuardarResenaRequest(Integer idAutor, String contenido) {
    }

    public record ResenaResponse(
            int idAutor,
            String autor,
            String avatar,
            String contenido,
            Timestamp fechaCreacion
    ) {
    }

    private record SavedReview(int authorId, String content, Timestamp createdAt) {
    }
}
