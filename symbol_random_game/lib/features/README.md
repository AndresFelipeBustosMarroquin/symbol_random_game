# Estructura de features

Cada carpeta en `features/` agrupa el código de una parte del juego. Las capas
se usan cuando la feature las necesita:

- `presentation/`: pantallas y widgets de esa feature.
- `domain/`: modelos y reglas propios, sin acceso a la red.
- `data/`: servicios que llaman a la API y convierten sus respuestas en modelos.

El flujo habitual es `presentation -> data -> core/network -> backend`. La
interfaz conserva el estado y la navegación; los servicios reúnen las llamadas
HTTP; `ApiClient` centraliza la conexión.

## Features

- `auth/`: inicio de sesión, registro y usuarios.
- `home/`: pantalla principal y frases.
- `game/`: juego individual, duelo y retos de operaciones.
- `settings/`: opciones y configuración.
- `leaderboard/`: resultados y clasificación.
- `profile/`: perfil y reseñas.
- `friends/`: amistades y solicitudes.
- `chat/`: mensajes entre amistades.

No todas las features necesitan las tres capas. Por ejemplo, `game/domain/`
contiene las reglas de retos, mientras `leaderboard/` obtiene los puntajes desde
la API y los muestra.

## Código compartido

- `core/`: tema, tipografía, configuración, red y audio de la aplicación.
- `shared/`: widgets reutilizables que no pertenecen a una sola feature.

Las pruebas están en `test/` y se organizan por comportamiento; no duplican la
estructura de producción.
