package com.symbolrandomgame.backend.infrastructure.adapter.in;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/amistades")
public class AmistadController {

    private final JdbcTemplate jdbcTemplate;

    public AmistadController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public AmistadesResponse obtener(@PathVariable int idUsuario) {
        validarUsuario(idUsuario);
        var amigos = jdbcTemplate.query(
                """
                SELECT u.id_usuario, u.nombre_uso, u.avatar
                FROM amistad a
                JOIN usuario u ON u.id_usuario = CASE
                    WHEN a.id_usuario_menor = ? THEN a.id_usuario_mayor
                    ELSE a.id_usuario_menor
                END
                WHERE (a.id_usuario_menor = ? OR a.id_usuario_mayor = ?)
                  AND a.estado = 'ACEPTADA'
                ORDER BY lower(u.nombre_uso)
                """,
                (rs, row) -> new PersonaAmistad(
                        rs.getInt("id_usuario"),
                        rs.getString("nombre_uso"),
                        rs.getString("avatar")
                ),
                idUsuario, idUsuario, idUsuario
        );
        var recibidas = solicitudes(idUsuario, false);
        var enviadas = solicitudes(idUsuario, true);
        return new AmistadesResponse(amigos, recibidas, enviadas);
    }

    @GetMapping("/{idOtro}")
    public EstadoAmistadResponse estado(
            @PathVariable int idUsuario,
            @PathVariable int idOtro
    ) {
        validarPar(idUsuario, idOtro);
        var rows = jdbcTemplate.query(
                """
                SELECT estado, id_solicitante
                FROM amistad
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                """,
                (rs, row) -> new EstadoAmistadResponse(
                        rs.getString("estado"),
                        rs.getInt("id_solicitante")
                ),
                Math.min(idUsuario, idOtro),
                Math.max(idUsuario, idOtro)
        );
        if (rows.isEmpty()) {
            return new EstadoAmistadResponse("NINGUNA", null);
        }
        var row = rows.get(0);
        if ("ACEPTADA".equals(row.estado())) {
            return new EstadoAmistadResponse("AMIGOS", null);
        }
        return new EstadoAmistadResponse(
                row.idSolicitante() == idUsuario ? "ENVIADA" : "RECIBIDA",
                row.idSolicitante()
        );
    }

    @PostMapping("/{idDestino}")
    @Transactional
    public EstadoAmistadResponse solicitar(
            @PathVariable int idUsuario,
            @PathVariable int idDestino
    ) {
        validarPar(idUsuario, idDestino);
        int inserted = jdbcTemplate.update(
                """
                INSERT INTO amistad (
                    id_usuario_menor, id_usuario_mayor, id_solicitante, estado
                ) VALUES (?, ?, ?, 'PENDIENTE')
                ON CONFLICT (id_usuario_menor, id_usuario_mayor) DO NOTHING
                """,
                Math.min(idUsuario, idDestino),
                Math.max(idUsuario, idDestino),
                idUsuario
        );
        if (inserted == 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ya existe una solicitud o amistad con este usuario"
            );
        }
        return new EstadoAmistadResponse("ENVIADA", idUsuario);
    }

    @PostMapping("/{idOtro}/aceptar")
    @Transactional
    public EstadoAmistadResponse aceptar(
            @PathVariable int idUsuario,
            @PathVariable int idOtro
    ) {
        validarPar(idUsuario, idOtro);
        int updated = jdbcTemplate.update(
                """
                UPDATE amistad
                SET estado = 'ACEPTADA', fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                  AND id_solicitante = ? AND estado = 'PENDIENTE'
                """,
                Math.min(idUsuario, idOtro),
                Math.max(idUsuario, idOtro),
                idOtro
        );
        if (updated == 0) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "No se encontró una solicitud pendiente de este usuario"
            );
        }
        return new EstadoAmistadResponse("AMIGOS", null);
    }

    @DeleteMapping("/{idOtro}")
    @Transactional
    public void eliminar(
            @PathVariable int idUsuario,
            @PathVariable int idOtro
    ) {
        validarPar(idUsuario, idOtro);
        jdbcTemplate.update(
                """
                DELETE FROM amistad
                WHERE id_usuario_menor = ? AND id_usuario_mayor = ?
                """,
                Math.min(idUsuario, idOtro),
                Math.max(idUsuario, idOtro)
        );
    }

    private List<PersonaAmistad> solicitudes(int idUsuario, boolean enviadas) {
        String condition = enviadas
                ? "a.id_solicitante = ?"
                : "a.id_solicitante <> ?";
        return jdbcTemplate.query(
                """
                SELECT u.id_usuario, u.nombre_uso, u.avatar
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
                        rs.getInt("id_usuario"),
                        rs.getString("nombre_uso"),
                        rs.getString("avatar")
                ),
                idUsuario, idUsuario, idUsuario, idUsuario
        );
    }

    private void validarPar(int idUsuario, int idOtro) {
        validarUsuario(idUsuario);
        validarUsuario(idOtro);
        if (idUsuario == idOtro) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "No puedes enviarte una solicitud de amistad"
            );
        }
    }

    private void validarUsuario(int idUsuario) {
        Integer exists = jdbcTemplate.query(
                "SELECT id_usuario FROM usuario WHERE id_usuario = ?",
                rs -> rs.next() ? rs.getInt(1) : null,
                idUsuario
        );
        if (exists == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "El usuario no existe");
        }
    }

    public record PersonaAmistad(int idUsuario, String nombreUso, String avatar) {}

    public record AmistadesResponse(
            List<PersonaAmistad> amigos,
            List<PersonaAmistad> recibidas,
            List<PersonaAmistad> enviadas
    ) {}

    public record EstadoAmistadResponse(String estado, Integer idSolicitante) {}
}
