package com.symbolrandomgame.backend.infrastructure.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
public class ConfiguracionSchemaInitializer implements ApplicationRunner {

    private final JdbcTemplate jdbcTemplate;

    public ConfiguracionSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        jdbcTemplate.execute("""
                ALTER TABLE configuraciones
                    ADD COLUMN IF NOT EXISTS tiempo_co integer NOT NULL DEFAULT 5,
                    ADD COLUMN IF NOT EXISTS volumen double precision NOT NULL DEFAULT 0.5,
                    ADD COLUMN IF NOT EXISTS fuente integer NOT NULL DEFAULT 0
                """);
        jdbcTemplate.execute(
                "ALTER TABLE configuraciones ALTER COLUMN sonido SET DEFAULT 0"
        );
        jdbcTemplate.execute("""
                ALTER TABLE usuario
                    ADD COLUMN IF NOT EXISTS descripcion character varying(180)
                        NOT NULL DEFAULT '',
                    ADD COLUMN IF NOT EXISTS avatar character varying(24)
                        NOT NULL DEFAULT 'astronauta'
                """);
        jdbcTemplate.execute("""
                COMMENT ON TABLE public.avatar IS 'Catálogo de avatares disponibles para los usuarios del juego.';
                COMMENT ON COLUMN public.avatar.id_avatar IS 'Identificador único del avatar.';
                COMMENT ON COLUMN public.avatar.nombre IS 'Nombre visible del avatar.';
                COMMENT ON COLUMN public.avatar.imagen_url IS 'Ruta o URL de la imagen del avatar.';
                COMMENT ON TABLE public.configuraciones IS 'Configuración personal de cada usuario dentro del juego.';
                COMMENT ON COLUMN public.configuraciones.id_configuracion IS 'Identificador único de la configuración.';
                COMMENT ON COLUMN public.configuraciones.sonido IS 'Indica si el sonido está activado o desactivado.';
                COMMENT ON COLUMN public.configuraciones.vidas_co IS 'Número de vidas configuradas para la partida.';
                COMMENT ON COLUMN public.configuraciones.digitos_co IS 'Cantidad de dígitos que se usarán en la configuración actual.';
                COMMENT ON COLUMN public.configuraciones.id_paleta IS 'Referencia a la paleta visual seleccionada por el usuario.';
                COMMENT ON COLUMN public.configuraciones.id_avatar IS 'Referencia al avatar seleccionado por el usuario.';
                COMMENT ON COLUMN public.configuraciones.id_usuario IS 'Usuario al que pertenece esta configuración.';
                COMMENT ON COLUMN public.configuraciones.tiempo_co IS 'Tiempo límite por pregunta o turno configurado.';
                COMMENT ON COLUMN public.configuraciones.volumen IS 'Nivel del volumen de audio configurado.';
                COMMENT ON COLUMN public.configuraciones.fuente IS 'Tipo de fuente o estilo visual seleccionado.';
                COMMENT ON TABLE public.mensaje IS 'Mensajes asociados a un nivel según el momento del juego.';
                COMMENT ON COLUMN public.mensaje.id_mensaje IS 'Identificador único del mensaje.';
                COMMENT ON COLUMN public.mensaje.id_nivel IS 'Nivel al que pertenece el mensaje.';
                COMMENT ON COLUMN public.mensaje.contenido IS 'Texto del mensaje mostrado al jugador.';
                COMMENT ON COLUMN public.mensaje.momento IS 'Momento del juego en que se muestra el mensaje.';
                COMMENT ON TABLE public.modo_juego IS 'Modos de juego disponibles en la aplicación.';
                COMMENT ON COLUMN public.modo_juego.id_modo IS 'Identificador único del modo de juego.';
                COMMENT ON COLUMN public.modo_juego.nombre_modo IS 'Nombre del modo de juego.';
                COMMENT ON COLUMN public.modo_juego.descripcion IS 'Descripción general del modo de juego.';
                COMMENT ON TABLE public.nivel IS 'Definición de los niveles del juego.';
                COMMENT ON COLUMN public.nivel.id_nivel IS 'Identificador único del nivel.';
                COMMENT ON COLUMN public.nivel.id_modo IS 'Modo de juego al que pertenece el nivel.';
                COMMENT ON COLUMN public.nivel.nombre_nivel IS 'Nombre del nivel.';
                COMMENT ON COLUMN public.nivel.digitos_base IS 'Cantidad base de dígitos utilizados en este nivel.';
                COMMENT ON COLUMN public.nivel.tiempo_base IS 'Tiempo base asignado para responder en el nivel.';
                COMMENT ON COLUMN public.nivel.vidas_base IS 'Número base de vidas disponible para este nivel.';
                COMMENT ON TABLE public.paleta IS 'Paletas de colores disponibles para personalizar la interfaz.';
                COMMENT ON COLUMN public.paleta.id_paleta IS 'Identificador único de la paleta.';
                COMMENT ON COLUMN public.paleta.nombre IS 'Nombre descriptivo de la paleta.';
                COMMENT ON COLUMN public.paleta.color_primario IS 'Color principal de la paleta.';
                COMMENT ON COLUMN public.paleta.color_secundario IS 'Color secundario de la paleta.';
                COMMENT ON COLUMN public.paleta.color_fondo IS 'Color de fondo de la paleta.';
                COMMENT ON TABLE public.partida IS 'Registro de una partida jugada por un usuario.';
                COMMENT ON COLUMN public.partida.id_partida IS 'Identificador único de la partida.';
                COMMENT ON COLUMN public.partida.id_usuario IS 'Usuario que inició la partida.';
                COMMENT ON COLUMN public.partida.id_modo IS 'Modo de juego seleccionado en la partida.';
                COMMENT ON COLUMN public.partida.id_nivel IS 'Nivel activo o final de la partida.';
                COMMENT ON COLUMN public.partida.fecha_inicio IS 'Fecha y hora en que comenzó la partida.';
                COMMENT ON COLUMN public.partida.fecha_fin IS 'Fecha y hora en que finalizó la partida, si existe.';
                COMMENT ON COLUMN public.partida.resultado IS 'Resultado general de la partida.';
                COMMENT ON TABLE public.puntuacion IS 'Puntuación obtenida por un usuario en una partida.';
                COMMENT ON COLUMN public.puntuacion.id_puntuacion IS 'Identificador único de la puntuación.';
                COMMENT ON COLUMN public.puntuacion.nivel IS 'Nivel asociado a la puntuación registrada.';
                COMMENT ON COLUMN public.puntuacion.digitos IS 'Cantidad de dígitos considerados en el cálculo.';
                COMMENT ON COLUMN public.puntuacion.vidas_pun IS 'Vidas restantes o utilizadas en la puntuación.';
                COMMENT ON COLUMN public.puntuacion.tiempo_pregunta IS 'Tiempo gastado por pregunta.';
                COMMENT ON COLUMN public.puntuacion.tiempo_total IS 'Tiempo total empleado durante la evaluación.';
                COMMENT ON COLUMN public.puntuacion.resultado IS 'Puntaje final registrado para la partida.';
                COMMENT ON COLUMN public.puntuacion.id_usuario IS 'Usuario dueño de la puntuación.';
                COMMENT ON COLUMN public.puntuacion.id_partida IS 'Partida asociada a esta puntuación.';
                COMMENT ON TABLE public.ranking IS 'Ranking general de puntajes por usuario, modo y nivel.';
                COMMENT ON COLUMN public.ranking.id_ranking IS 'Identificador único del registro de ranking.';
                COMMENT ON COLUMN public.ranking.id_usuario IS 'Usuario al que corresponde el ranking.';
                COMMENT ON COLUMN public.ranking.id_modo IS 'Modo de juego del ranking.';
                COMMENT ON COLUMN public.ranking.id_nivel IS 'Nivel del ranking.';
                COMMENT ON COLUMN public.ranking.mejor_puntaje IS 'Mejor puntaje registrado por el usuario en ese contexto.';
                COMMENT ON COLUMN public.ranking.promedio_puntaje IS 'Promedio de puntajes del usuario en ese contexto.';
                COMMENT ON COLUMN public.ranking.fecha_actualizacion IS 'Fecha de la última actualización del ranking.';
                COMMENT ON TABLE public.usuario IS 'Usuarios registrados en la aplicación.';
                COMMENT ON COLUMN public.usuario.id_usuario IS 'Identificador único del usuario.';
                COMMENT ON COLUMN public.usuario.nombre_uso IS 'Nombre de usuario usado para iniciar sesión.';
                COMMENT ON COLUMN public.usuario.contrasena_us IS 'Contraseña cifrada del usuario.';
                COMMENT ON COLUMN public.usuario.fecha_nacimiento IS 'Fecha de nacimiento del usuario.';
                COMMENT ON COLUMN public.usuario.descripcion IS 'Descripción pública del perfil del usuario.';
                COMMENT ON COLUMN public.usuario.avatar IS 'Avatar predeterminado asociado al usuario.';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS resena_perfil (
                    id_resena integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                    id_autor integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    id_perfil integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    contenido character varying(500) NOT NULL,
                    fecha_creacion timestamp without time zone NOT NULL
                        DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT uq_resena_autor_perfil UNIQUE (id_autor, id_perfil),
                    CONSTRAINT ck_resena_no_autorreferencia CHECK (id_autor <> id_perfil),
                    CONSTRAINT ck_resena_contenido CHECK (length(trim(contenido)) > 0)
                )
                """);
        jdbcTemplate.execute("""
                COMMENT ON TABLE public.resena_perfil IS 'Reseñas escritas por un usuario sobre el perfil de otro usuario.';
                COMMENT ON COLUMN public.resena_perfil.id_resena IS 'Identificador único de la reseña.';
                COMMENT ON COLUMN public.resena_perfil.id_autor IS 'Usuario que redacta la reseña.';
                COMMENT ON COLUMN public.resena_perfil.id_perfil IS 'Usuario sobre quien se escribe la reseña.';
                COMMENT ON COLUMN public.resena_perfil.contenido IS 'Texto de la reseña.';
                COMMENT ON COLUMN public.resena_perfil.fecha_creacion IS 'Fecha y hora en que se creó la reseña.';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS amistad (
                    id_usuario_menor integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    id_usuario_mayor integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    id_solicitante integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    estado character varying(12) NOT NULL DEFAULT 'PENDIENTE',
                    fecha_actualizacion timestamp without time zone NOT NULL
                        DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT pk_amistad PRIMARY KEY (
                        id_usuario_menor, id_usuario_mayor
                    ),
                    CONSTRAINT ck_amistad_usuarios_ordenados CHECK (
                        id_usuario_menor < id_usuario_mayor
                    ),
                    CONSTRAINT ck_amistad_solicitante CHECK (
                        id_solicitante = id_usuario_menor
                        OR id_solicitante = id_usuario_mayor
                    ),
                    CONSTRAINT ck_amistad_estado CHECK (
                        estado IN ('PENDIENTE', 'ACEPTADA')
                    )
                )
                """);
        jdbcTemplate.execute("""
                COMMENT ON TABLE public.amistad IS 'Relación de amistad entre dos usuarios y su estado.';
                COMMENT ON COLUMN public.amistad.id_usuario_menor IS 'Identificador del usuario con menor ID en la relación.';
                COMMENT ON COLUMN public.amistad.id_usuario_mayor IS 'Identificador del usuario con mayor ID en la relación.';
                COMMENT ON COLUMN public.amistad.id_solicitante IS 'Usuario que inició la solicitud de amistad.';
                COMMENT ON COLUMN public.amistad.estado IS 'Estado actual de la relación: pendiente o aceptada.';
                COMMENT ON COLUMN public.amistad.fecha_actualizacion IS 'Fecha de la última actualización del estado de la amistad.';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS chat_mensaje (
                    id_mensaje bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                    id_emisor integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    id_receptor integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    contenido character varying(1000) NOT NULL,
                    fecha_envio timestamp without time zone NOT NULL
                        DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT ck_chat_mensaje_distintos CHECK (id_emisor <> id_receptor),
                    CONSTRAINT ck_chat_mensaje_contenido CHECK (
                        length(trim(contenido)) > 0
                    )
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS chat_lectura (
                    id_usuario integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    id_amigo integer NOT NULL REFERENCES usuario(id_usuario)
                        ON DELETE CASCADE,
                    ultimo_mensaje_visto bigint NOT NULL DEFAULT 0,
                    fecha_actualizacion timestamp without time zone NOT NULL
                        DEFAULT CURRENT_TIMESTAMP,
                    CONSTRAINT pk_chat_lectura PRIMARY KEY (id_usuario, id_amigo),
                    CONSTRAINT ck_chat_lectura_usuarios_distintos
                        CHECK (id_usuario <> id_amigo),
                    CONSTRAINT ck_chat_lectura_mensaje_no_negativo
                        CHECK (ultimo_mensaje_visto >= 0)
                )
                """);
        jdbcTemplate.execute("""
                COMMENT ON TABLE public.chat_mensaje IS 'Mensajes privados enviados entre usuarios.';
                COMMENT ON COLUMN public.chat_mensaje.id_mensaje IS 'Identificador único del mensaje del chat.';
                COMMENT ON COLUMN public.chat_mensaje.id_emisor IS 'Usuario que envió el mensaje.';
                COMMENT ON COLUMN public.chat_mensaje.id_receptor IS 'Usuario que recibió el mensaje.';
                COMMENT ON COLUMN public.chat_mensaje.contenido IS 'Contenido del mensaje privado.';
                COMMENT ON COLUMN public.chat_mensaje.fecha_envio IS 'Fecha y hora en que se envió el mensaje.';
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS ix_chat_mensaje_participantes_fecha
                ON chat_mensaje (id_emisor, id_receptor, fecha_envio, id_mensaje)
                """);
        jdbcTemplate.execute("""
                CREATE INDEX IF NOT EXISTS ix_chat_mensaje_no_vistos
                ON chat_mensaje (id_receptor, id_emisor, id_mensaje)
                """);
        jdbcTemplate.update(
                """
                INSERT INTO modo_juego (nombre_modo, descripcion)
                SELECT 'OPERACIONES', 'Resuelve operaciones de básico a avanzado'
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM modo_juego
                    WHERE lower(nombre_modo) = lower('OPERACIONES')
                )
                """
        );

        for (var palette : PALETTES) {
            jdbcTemplate.update(
                    """
                    INSERT INTO paleta (
                        nombre, color_primario, color_secundario, color_fondo
                    )
                    SELECT ?, ?, ?, ?
                    WHERE NOT EXISTS (
                        SELECT 1 FROM paleta WHERE lower(nombre) = lower(?)
                    )
                    """,
                    palette.name(),
                    palette.primary(),
                    palette.secondary(),
                    palette.background(),
                    palette.name()
            );
        }

        jdbcTemplate.update(
                """
                INSERT INTO avatar (nombre, imagen_url)
                SELECT 'Predeterminado', 'assets/avatar_default.png'
                WHERE NOT EXISTS (SELECT 1 FROM avatar)
                """
        );
    }

    private static final List<PaletteSeed> PALETTES = List.of(
            new PaletteSeed("Violeta", "#5B5FEF", "#8E9BFF", "#10152F"),
            new PaletteSeed("Océano", "#0891B2", "#67E8F9", "#082B3A"),
            new PaletteSeed("Esmeralda", "#059669", "#6EE7B7", "#092C25"),
            new PaletteSeed("Atardecer", "#E0528A", "#FFA3C7", "#35162D"),
            new PaletteSeed("Ámbar", "#D97706", "#FCD34D", "#34220D"),
            new PaletteSeed("Rojo", "#DC2626", "#FCA5A5", "#351416")
    );

    private record PaletteSeed(
            String name,
            String primary,
            String secondary,
            String background
    ) {
    }
}
