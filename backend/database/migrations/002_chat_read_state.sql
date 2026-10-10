CREATE TABLE IF NOT EXISTS chat_lectura (
    id_usuario integer NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_amigo integer NOT NULL REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    ultimo_mensaje_visto bigint NOT NULL DEFAULT 0,
    fecha_actualizacion timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_chat_lectura PRIMARY KEY (id_usuario, id_amigo),
    CONSTRAINT ck_chat_lectura_usuarios_distintos CHECK (id_usuario <> id_amigo),
    CONSTRAINT ck_chat_lectura_mensaje_no_negativo CHECK (ultimo_mensaje_visto >= 0)
);

CREATE INDEX IF NOT EXISTS ix_chat_mensaje_no_vistos
    ON chat_mensaje (id_receptor, id_emisor, id_mensaje);
