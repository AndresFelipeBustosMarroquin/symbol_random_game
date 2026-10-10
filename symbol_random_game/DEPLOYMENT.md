# Publicar Flutter Web en Render

El backend Spring Boot ya se publica como **Web Service**. La interfaz Flutter
se despliega aparte como **Static Site**:

1. En Render, crea un **New + > Static Site** y conecta este repositorio.
2. Configura la rama `main` y el directorio raíz `symbol_random_game`.
3. Usa este comando de compilación:

   ```sh
   git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter-sdk && /tmp/flutter-sdk/bin/flutter pub get && /tmp/flutter-sdk/bin/flutter build web --release --dart-define=API_BASE_URL=https://symbol-random-game.onrender.com/api
   ```

4. Configura `build/web` como **Publish Directory** y crea el servicio.
5. Cuando Render muestre la URL asignada al Static Site, abre el servicio
   backend y agrega una variable de entorno `CORS_ALLOWED_ORIGINS` con ese
   origen exacto, por ejemplo `https://symbol-random-game-ui.onrender.com`.
   No incluyas una barra final ni rutas. Guarda y espera a que Render
   redespliegue el backend.
6. Abre la URL del Static Site y prueba la aplicación.

No hace falta configurar variables secretas en Flutter. El comando compila la
URL pública del backend; `API_BASE_URL` también puede cambiarse al compilar
localmente. En el desarrollo local se conserva
`http://localhost:8080/api` por defecto. El backend permite localhost por
defecto para desarrollo y solo agrega otros orígenes cuando se configuran en
`CORS_ALLOWED_ORIGINS`.
