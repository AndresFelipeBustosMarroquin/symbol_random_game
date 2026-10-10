package com.symbolrandomgame.backend.infrastructure.adapter.in;

import com.symbolrandomgame.backend.domain.model.Usuario;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@Transactional
class SocialAndScoreFlowIntegrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private AmistadController amistadController;

    @Autowired
    private ChatController chatController;

    @Autowired
    private PuntuacionController puntuacionController;

    @Autowired
    private UsuarioController usuarioController;

    @Test
    void nombreExistenteSeRespondeComoConflictoYNoRestringeContrasenasRepetidas() {
        String existingName = jdbcTemplate.queryForObject(
                "SELECT nombre_uso FROM usuario ORDER BY id_usuario LIMIT 1",
                String.class
        );
        String existingPassword = jdbcTemplate.queryForObject(
                "SELECT contrasena_us FROM usuario ORDER BY id_usuario LIMIT 1",
                String.class
        );

        var conflict = assertThrows(
                ResponseStatusException.class,
                () -> usuarioController.crear(new Usuario(
                        null,
                        existingName,
                        "una-clave-distinta",
                        LocalDate.of(2000, 1, 1)
                ))
        );
        assertEquals(409, conflict.getStatusCode().value());

        var created = usuarioController.crear(
                new Usuario(
                        null,
                        "repeat_password_" + UUID.randomUUID()
                                .toString().replace("-", ""),
                        existingPassword,
                        LocalDate.of(2000, 1, 1)
                )
        );
        assertEquals(existingPassword, created.getContrasenaUs());
    }

    @Test
    void unaSolicitudEnviadaSeRecibeYSePuedeAceptar() {
        int solicitante = crearUsuario();
        int destinatario = crearUsuario();

        assertEquals(
                "ENVIADA",
                amistadController.solicitar(solicitante, destinatario).estado()
        );
        assertTrue(
                amistadController.obtener(destinatario).recibidas().stream()
                        .anyMatch(persona -> persona.idUsuario() == solicitante)
        );

        amistadController.aceptar(destinatario, solicitante);

        assertTrue(
                amistadController.obtener(destinatario).amigos().stream()
                        .anyMatch(persona -> persona.idUsuario() == solicitante)
        );
    }

    @Test
    void cuentaMensajesNoVistosYAlAbrirElChatSeMarcanComoVistos() {
        int emisor = crearUsuario();
        int receptor = crearUsuario();
        int menor = Math.min(emisor, receptor);
        int mayor = Math.max(emisor, receptor);
        jdbcTemplate.update(
                """
                INSERT INTO amistad (
                    id_usuario_menor, id_usuario_mayor, id_solicitante, estado
                ) VALUES (?, ?, ?, 'ACEPTADA')
                """,
                menor,
                mayor,
                emisor
        );
        jdbcTemplate.update(
                """
                INSERT INTO chat_mensaje (id_emisor, id_receptor, contenido)
                VALUES (?, ?, ?)
                """,
                emisor,
                receptor,
                "Mensaje de prueba"
        );

        var friend = amistadController.obtener(receptor).amigos().stream()
                .filter(persona -> persona.idUsuario() == emisor)
                .findFirst()
                .orElseThrow();
        assertEquals(1, friend.mensajesNoVistos());

        chatController.obtener(receptor, emisor);

        friend = amistadController.obtener(receptor).amigos().stream()
                .filter(persona -> persona.idUsuario() == emisor)
                .findFirst()
                .orElseThrow();
        assertEquals(0, friend.mensajesNoVistos());

        jdbcTemplate.update(
                """
                INSERT INTO chat_mensaje (id_emisor, id_receptor, contenido)
                VALUES (?, ?, ?)
                """,
                emisor,
                receptor,
                "Otro mensaje de prueba"
        );
        friend = amistadController.obtener(receptor).amigos().stream()
                .filter(persona -> persona.idUsuario() == emisor)
                .findFirst()
                .orElseThrow();
        assertEquals(1, friend.mensajesNoVistos());
    }

    @Test
    void soloElCreadorPuedeEliminarLaPuntuacion() {
        int propietario = crearUsuario();
        int otroUsuario = crearUsuario();
        int modo = jdbcTemplate.queryForObject(
                """
                INSERT INTO modo_juego (nombre_modo, descripcion)
                VALUES (?, ?)
                RETURNING id_modo
                """,
                Integer.class,
                "N??MEROS",
                "Modo para prueba de puntuación"
        );
        int nivel = jdbcTemplate.queryForObject(
                """
                INSERT INTO nivel (
                    id_modo, nombre_nivel, digitos_base, tiempo_base, vidas_base
                )
                VALUES (?, ?, 1, 10, 3)
                RETURNING id_nivel
                """,
                Integer.class,
                modo,
                "Nivel de prueba"
        );
        LocalDateTime inicio = LocalDateTime.now();
        int partida = jdbcTemplate.queryForObject(
                """
                INSERT INTO partida (
                    id_usuario, id_modo, id_nivel, fecha_inicio, fecha_fin, resultado
                )
                VALUES (?, ?, ?, ?, ?, 100)
                RETURNING id_partida
                """,
                Integer.class,
                propietario,
                modo,
                nivel,
                inicio,
                inicio.plusMinutes(1)
        );
        int puntuacion = jdbcTemplate.queryForObject(
                """
                INSERT INTO puntuacion (
                    nivel, digitos, vidas_pun, tiempo_pregunta, tiempo_total,
                    resultado, id_usuario, id_partida
                )
                VALUES ('Nivel de prueba', 1, 3, 10, 60, 100, ?, ?)
                RETURNING id_puntuacion
                """,
                Integer.class,
                propietario,
                partida
        );

        var response = puntuacionController.obtenerTodas().stream()
                .filter(row -> row.idPuntuacion() == puntuacion)
                .findFirst()
                .orElseThrow();
        assertEquals(propietario, response.idUsuario());
        assertEquals("NÚMEROS", response.modo());

        var forbidden = assertThrows(
                ResponseStatusException.class,
                () -> puntuacionController.eliminar(puntuacion, otroUsuario)
        );
        assertEquals(403, forbidden.getStatusCode().value());
        assertEquals(
                1,
                jdbcTemplate.queryForObject(
                        "SELECT count(*) FROM puntuacion WHERE id_puntuacion = ?",
                        Integer.class,
                        puntuacion
                )
        );

        puntuacionController.eliminar(puntuacion, propietario);

        assertEquals(
                0,
                jdbcTemplate.queryForObject(
                        "SELECT count(*) FROM puntuacion WHERE id_puntuacion = ?",
                        Integer.class,
                        puntuacion
                )
        );
        assertEquals(
                0,
                jdbcTemplate.queryForObject(
                        "SELECT count(*) FROM partida WHERE id_partida = ?",
                        Integer.class,
                        partida
                )
        );
    }

    private int crearUsuario() {
        return jdbcTemplate.queryForObject(
                """
                INSERT INTO usuario (nombre_uso, contrasena_us, fecha_nacimiento)
                VALUES (?, 'test-password', ?)
                RETURNING id_usuario
                """,
                Integer.class,
                "test_" + UUID.randomUUID().toString().replace("-", ""),
                LocalDate.of(2000, 1, 1)
        );
    }
}
