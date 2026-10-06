package com.symbolrandomgame.backend.infrastructure.adapter.in;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.text.Normalizer;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/api/puntuaciones")
public class PuntuacionController {

    private static final String CONSULTA_PUNTUACIONES = """
            SELECT u.id_usuario,
                   u.nombre_uso,
                   m.nombre_modo,
                   p.digitos,
                   p.vidas_pun,
                   p.tiempo_pregunta,
                   p.tiempo_total,
                   p.resultado,
                   u.fecha_nacimiento
            FROM puntuacion p
            JOIN usuario u ON u.id_usuario = p.id_usuario
            JOIN partida pa ON pa.id_partida = p.id_partida
            JOIN modo_juego m ON m.id_modo = pa.id_modo
            ORDER BY p.resultado DESC, p.id_puntuacion ASC
            """;

    private final JdbcTemplate jdbcTemplate;

    public PuntuacionController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public List<PuntuacionResponse> obtenerTodas() {
        return jdbcTemplate.query(
                CONSULTA_PUNTUACIONES,
                (resultSet, rowNumber) -> new PuntuacionResponse(
                        resultSet.getInt("id_usuario"),
                        resultSet.getString("nombre_uso"),
                        resultSet.getString("nombre_modo"),
                        resultSet.getInt("digitos"),
                        resultSet.getInt("vidas_pun"),
                        resultSet.getInt("tiempo_pregunta"),
                        resultSet.getInt("tiempo_total"),
                        resultSet.getInt("resultado"),
                        Period.between(
                                resultSet.getDate("fecha_nacimiento").toLocalDate(),
                                LocalDate.now()
                        ).getYears()
                )
        );
    }

    @PostMapping
    @org.springframework.web.bind.annotation.ResponseStatus(HttpStatus.CREATED)
    @Transactional
    public void guardar(@RequestBody GuardarPuntuacionRequest request) {
        validar(request);

        Integer usuarioExiste = jdbcTemplate.query(
                "SELECT id_usuario FROM usuario WHERE id_usuario = ?",
                resultSet -> resultSet.next() ? resultSet.getInt(1) : null,
                request.idUsuario()
        );
        if (usuarioExiste == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "El usuario no existe"
            );
        }

        String modoNombre = nombreCanonico(request.modo());
        Integer modoId = jdbcTemplate.query(
                "SELECT id_modo, nombre_modo FROM modo_juego",
                resultSet -> {
                    while (resultSet.next()) {
                        if (normalizar(resultSet.getString("nombre_modo"))
                                .equals(normalizar(modoNombre))) {
                            return resultSet.getInt("id_modo");
                        }
                    }
                    return null;
                }
        );
        if (modoId == null) {
            modoId = jdbcTemplate.queryForObject(
                    """
                    INSERT INTO modo_juego (nombre_modo, descripcion)
                    VALUES (?, ?)
                    RETURNING id_modo
                    """,
                    Integer.class,
                    modoNombre,
                    "Modo de juego"
            );
        }
        if (modoId == null) {
            throw new IllegalStateException("No se pudo crear el modo de juego");
        }

        String nombreNivel = "PERSONALIZADO I%d T%d V%d".formatted(
                request.digitos(),
                request.tiempoPregunta(),
                request.vidas()
        );
        var niveles = jdbcTemplate.query(
                """
                INSERT INTO nivel (
                    id_modo, nombre_nivel, digitos_base, tiempo_base, vidas_base
                )
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT (id_modo, digitos_base, tiempo_base, vidas_base)
                DO UPDATE SET nombre_nivel = EXCLUDED.nombre_nivel
                RETURNING id_nivel, nombre_nivel
                """,
                (resultSet, rowNumber) -> new NivelReferencia(
                        resultSet.getInt("id_nivel"),
                        resultSet.getString("nombre_nivel")
                ),
                modoId,
                nombreNivel,
                request.digitos(),
                request.tiempoPregunta(),
                request.vidas()
        );
        if (niveles.isEmpty()) {
            throw new IllegalStateException("No se pudo guardar el nivel");
        }
        NivelReferencia nivel = niveles.get(0);

        LocalDateTime fin = LocalDateTime.now();
        LocalDateTime inicio = fin.minusSeconds(request.tiempoTotal());
        Integer partidaId = jdbcTemplate.queryForObject(
                """
                INSERT INTO partida (
                    id_usuario, id_modo, id_nivel, fecha_inicio, fecha_fin, resultado
                )
                VALUES (?, ?, ?, ?, ?, ?)
                RETURNING id_partida
                """,
                Integer.class,
                request.idUsuario(),
                modoId,
                nivel.id(),
                inicio,
                fin,
                request.resultado()
        );

        jdbcTemplate.update(
                """
                INSERT INTO puntuacion (
                    nivel, digitos, vidas_pun, tiempo_pregunta, tiempo_total,
                    resultado, id_usuario, id_partida
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                nivel.nombre(),
                request.digitos(),
                request.vidas(),
                request.tiempoPregunta(),
                request.tiempoTotal(),
                request.resultado(),
                request.idUsuario(),
                partidaId
        );
    }

    private void validar(GuardarPuntuacionRequest request) {
        if (request == null
                || request.idUsuario() == null
                || request.idUsuario() <= 0
                || request.modo() == null
                || !List.of("NUMEROS", "CARACTERES", "SIMBOLOS", "OPERACIONES")
                        .contains(normalizar(request.modo()))
                || request.digitos() == null
                || request.digitos() <= 0
                || request.vidas() == null
                || request.vidas() <= 0
                || request.tiempoPregunta() == null
                || request.tiempoPregunta() <= 0
                || request.tiempoTotal() == null
                || request.tiempoTotal() < 0
                || request.resultado() == null
                || request.resultado() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Los datos de la puntuación no son válidos"
            );
        }
    }

    private String nombreCanonico(String modo) {
        return switch (normalizar(modo)) {
            case "NUMEROS" -> "NÚMEROS";
            case "CARACTERES" -> "CARACTERES";
            case "SIMBOLOS" -> "SÍMBOLOS";
            case "OPERACIONES" -> "OPERACIONES";
            default -> throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El modo de juego no es válido"
            );
        };
    }

    private String normalizar(String value) {
        return Normalizer.normalize(value.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toUpperCase(Locale.ROOT);
    }

    private record NivelReferencia(int id, String nombre) {
    }
}
