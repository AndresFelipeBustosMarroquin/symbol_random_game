package com.symbolrandomgame.backend.infrastructure.adapter.in;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/api/usuarios/{idUsuario}/configuracion")
public class ConfiguracionController {

    private static final List<String> PALETAS = List.of(
            "Violeta", "Océano", "Esmeralda", "Atardecer", "Ámbar", "Rojo"
    );

    private final JdbcTemplate jdbcTemplate;

    public ConfiguracionController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping
    public ConfiguracionResponse obtener(@PathVariable int idUsuario) {
        validarUsuario(idUsuario);

        var configuraciones = jdbcTemplate.query(
                """
                SELECT c.digitos_co, c.vidas_co, c.tiempo_co, c.sonido,
                       p.nombre AS paleta, c.volumen, c.fuente
                FROM configuraciones c
                JOIN paleta p ON p.id_paleta = c.id_paleta
                WHERE c.id_usuario = ?
                """,
                (resultSet, rowNumber) -> new ConfiguracionResponse(
                        resultSet.getInt("digitos_co"),
                        resultSet.getInt("vidas_co"),
                        resultSet.getInt("tiempo_co"),
                        resultSet.getInt("sonido"),
                        indicePaleta(resultSet.getString("paleta")),
                        resultSet.getDouble("volumen"),
                        resultSet.getInt("fuente")
                ),
                idUsuario
        );

        return configuraciones.isEmpty()
                ? ConfiguracionResponse.predeterminada()
                : configuraciones.get(0);
    }

    @PutMapping
    public ConfiguracionResponse guardar(
            @PathVariable int idUsuario,
            @RequestBody ConfiguracionRequest request
    ) {
        validarUsuario(idUsuario);
        validar(request);

        String nombrePaleta = PALETAS.get(request.paleta());
        Integer idPaleta = jdbcTemplate.query(
                "SELECT id_paleta, nombre FROM paleta",
                resultSet -> {
                    while (resultSet.next()) {
                        if (normalizar(resultSet.getString("nombre"))
                                .equals(normalizar(nombrePaleta))) {
                            return resultSet.getInt("id_paleta");
                        }
                    }
                    return null;
                }
        );
        if (idPaleta == null) {
            throw new IllegalStateException(
                    "No se encontró la paleta " + nombrePaleta
            );
        }

        Integer idAvatar = jdbcTemplate.query(
                """
                SELECT id_avatar FROM configuraciones
                WHERE id_usuario = ?
                """,
                resultSet -> resultSet.next() ? resultSet.getInt(1) : null,
                idUsuario
        );
        if (idAvatar == null) {
            idAvatar = jdbcTemplate.query(
                    "SELECT id_avatar FROM avatar ORDER BY id_avatar LIMIT 1",
                    resultSet -> resultSet.next() ? resultSet.getInt(1) : null
            );
        }
        if (idAvatar == null) {
            throw new IllegalStateException(
                    "No hay un avatar predeterminado disponible"
            );
        }

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
                request.sonido(),
                request.vidas(),
                request.incremento(),
                idPaleta,
                idAvatar,
                idUsuario,
                request.tiempo(),
                request.volumen(),
                request.fuente()
        );

        return obtener(idUsuario);
    }

    private void validarUsuario(int idUsuario) {
        Integer existe = jdbcTemplate.query(
                "SELECT id_usuario FROM usuario WHERE id_usuario = ?",
                resultSet -> resultSet.next() ? resultSet.getInt(1) : null,
                idUsuario
        );
        if (existe == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "El usuario no existe"
            );
        }
    }

    private void validar(ConfiguracionRequest request) {
        if (request == null
                || request.incremento() == null
                || request.incremento() < 1
                || request.incremento() > 5
                || request.vidas() == null
                || request.vidas() < 1
                || request.vidas() > 5
                || request.tiempo() == null
                || request.tiempo() < 1
                || request.tiempo() > 60
                || request.sonido() == null
                || request.sonido() < 0
                || request.sonido() > 5
                || request.paleta() == null
                || request.paleta() < 0
                || request.paleta() >= PALETAS.size()
                || request.volumen() == null
                || request.volumen() < 0
                || request.volumen() > 1
                || request.fuente() == null
                || request.fuente() < 0
                || request.fuente() > 6) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Las preferencias no son válidas"
            );
        }
    }

    private int indicePaleta(String nombre) {
        String normalized = normalizar(nombre);
        for (int index = 0; index < PALETAS.size(); index++) {
            if (normalizar(PALETAS.get(index)).equals(normalized)) {
                return index;
            }
        }
        return 0;
    }

    private String normalizar(String value) {
        return Normalizer.normalize(value.trim(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toUpperCase(Locale.ROOT);
    }
}
