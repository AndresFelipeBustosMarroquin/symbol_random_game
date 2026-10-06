BEGIN;

CREATE UNIQUE INDEX IF NOT EXISTS uq_nivel_modo_configuracion
    ON nivel (id_modo, digitos_base, tiempo_base, vidas_base);

CREATE INDEX IF NOT EXISTS ix_partida_usuario_fecha
    ON partida (id_usuario, fecha_fin DESC);

CREATE INDEX IF NOT EXISTS ix_puntuacion_resultado
    ON puntuacion (resultado DESC, id_puntuacion);

CREATE INDEX IF NOT EXISTS ix_amistad_solicitudes
    ON amistad (id_solicitante, estado, fecha_actualizacion DESC);

CREATE INDEX IF NOT EXISTS ix_resena_perfil_fecha
    ON resena_perfil (id_perfil, fecha_creacion DESC, id_resena DESC);

CREATE INDEX IF NOT EXISTS ix_chat_mensaje_receptor_fecha
    ON chat_mensaje (id_receptor, id_emisor, fecha_envio, id_mensaje);

COMMIT;
