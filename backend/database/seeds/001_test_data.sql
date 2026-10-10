BEGIN;

INSERT INTO usuario (
    nombre_uso, contrasena_us, fecha_nacimiento, descripcion, avatar
)
SELECT
    'jugador_prueba_' || lpad(n::text, 2, '0'),
    'Prueba123!',
    DATE '1985-01-01' + (n * 200),
    'Cuenta de prueba para validar el juego.',
    'astronauta'
FROM generate_series(1, 50) AS numbers(n)
ON CONFLICT (nombre_uso) DO NOTHING;

INSERT INTO modo_juego (nombre_modo, descripcion)
SELECT modo, 'Modo de juego de datos de prueba'
FROM (VALUES ('NUMEROS'), ('CARACTERES'), ('SIMBOLOS'), ('OPERACIONES')) AS modos(modo)
WHERE NOT EXISTS (
    SELECT 1
    FROM modo_juego existente
    WHERE existente.nombre_modo = modos.modo
);

INSERT INTO nivel (
    id_modo, nombre_nivel, digitos_base, tiempo_base, vidas_base
)
SELECT
    m.id_modo,
    'PRUEBA D' || d.digitos,
    d.digitos,
    15 + d.digitos,
    3
FROM modo_juego m
CROSS JOIN generate_series(1, 5) AS d(digitos)
WHERE m.nombre_modo IN ('NUMEROS', 'CARACTERES', 'SIMBOLOS', 'OPERACIONES')
ON CONFLICT (id_modo, digitos_base, tiempo_base, vidas_base) DO NOTHING;

WITH fixtures AS (
    SELECT
        g.n,
        u.id_usuario,
        m.id_modo,
        l.id_nivel,
        ((g.n - 1) % 5) + 1 AS digitos,
        15 + (((g.n - 1) % 5) + 1) AS tiempo_pregunta,
        3 AS vidas,
        250 + (g.n * 17) AS resultado,
        TIMESTAMP '2025-01-01 00:00:00' + ((g.n - 1) * INTERVAL '1 hour') AS inicio
    FROM generate_series(1, 50) AS g(n)
    JOIN usuario u
      ON u.nombre_uso = 'jugador_prueba_' || lpad(g.n::text, 2, '0')
    JOIN modo_juego m
      ON m.nombre_modo = CASE (g.n - 1) % 4
          WHEN 0 THEN 'NUMEROS'
          WHEN 1 THEN 'CARACTERES'
          WHEN 2 THEN 'SIMBOLOS'
          ELSE 'OPERACIONES'
      END
    JOIN nivel l
      ON l.id_modo = m.id_modo
     AND l.digitos_base = ((g.n - 1) % 5) + 1
     AND l.tiempo_base = 15 + (((g.n - 1) % 5) + 1)
     AND l.vidas_base = 3
)
INSERT INTO partida (
    id_usuario, id_modo, id_nivel, fecha_inicio, fecha_fin, resultado
)
SELECT
    f.id_usuario,
    f.id_modo,
    f.id_nivel,
    f.inicio,
    f.inicio + INTERVAL '5 minutes',
    f.resultado
FROM fixtures f
WHERE NOT EXISTS (
    SELECT 1
    FROM partida existente
    WHERE existente.id_usuario = f.id_usuario
      AND existente.fecha_inicio = f.inicio
);

INSERT INTO puntuacion (
    nivel, digitos, vidas_pun, tiempo_pregunta, tiempo_total,
    resultado, id_usuario, id_partida
)
SELECT
    l.nombre_nivel,
    l.digitos_base,
    3,
    l.tiempo_base,
    300,
    pa.resultado,
    pa.id_usuario,
    pa.id_partida
FROM partida pa
JOIN usuario u ON u.id_usuario = pa.id_usuario
JOIN nivel l ON l.id_nivel = pa.id_nivel
WHERE left(u.nombre_uso, 15) = 'jugador_prueba_'
  AND pa.fecha_inicio >= TIMESTAMP '2025-01-01 00:00:00'
  AND pa.fecha_inicio < TIMESTAMP '2025-01-03 02:00:00'
  AND NOT EXISTS (
      SELECT 1
      FROM puntuacion existente
      WHERE existente.id_partida = pa.id_partida
  );

COMMIT;
