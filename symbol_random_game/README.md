# Symbol Random Game

Juego Flutter organizado por features para que pantallas, modelos y acceso a
datos se encuentren junto a la función a la que pertenecen.

## Cómo está organizado

```text
lib/
  core/       Servicios y configuración usados por varias features
  features/   Funciones del juego, organizadas por capas
  shared/     Widgets reutilizables entre pantallas
  main.dart   Punto de entrada
test/         Pruebas de modelos, pantallas y flujos
```

Dentro de una feature:

```text
features/<nombre>/
  presentation/  Pantallas e interacción
  domain/        Modelos y reglas de la función
  data/          Llamadas a la API y acceso a datos
```

Una feature puede omitir capas que no necesita. La interfaz usa los servicios
de su feature; estos llaman a `core/network/ApiClient`, que centraliza las
peticiones al backend. `core/` y `shared/` contienen lo que se reutiliza desde
varias features.

Consulta [la guía de features](lib/features/README.md) para ver la
responsabilidad de cada carpeta.

## Ejecutar y probar

Desde esta carpeta:

```text
flutter pub get
flutter run
flutter test
flutter analyze
```
