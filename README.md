# InstaDAM

InstaDAM: ejemplo práctico inspirado en Instagram, hecho con Flutter.

Requisitos:
- Flutter SDK instalado
- Plataforma: Android/iOS (explicación para Windows: usar emulador Android o VS Code)

Instalación y ejecución:

```bash
flutter pub get
flutter run
```

Notas:
- Usa `sqflite` para persistencia de posts y comentarios.
- Usa `shared_preferences` para usuario recordado, tema, idioma y perfil.
- Para seleccionar imágenes puedes usar URLs o el placeholder.

Ejecutar en Android Studio:

1. Abre la carpeta del proyecto en Android Studio.
2. Conecta o lanza un emulador Android.
3. Ejecuta `flutter pub get` (Android Studio suele ejecutarlo automáticamente).
4. Pulsa Run (Shift+F10) para iniciar la app en el emulador/dispositivo.

Estructura de la base de datos (SQFlite):

- `users` (id, username, displayName)
- `posts` (id, imageUrl, username, description, date, likes)
- `comments` (id, postId, username, text, date)
- `likes` (id, postId, username) — tabla para guardar qué usuario ha dado like a qué post. El conteo de likes en `posts.likes` se mantiene sincronizado.

Pruebas rápidas:

```bash
flutter pub get
flutter run
```

Notas finales:
- La app es un ejemplo educativo: en producción habría autenticación remota, almacenamiento de imágenes y manejo de múltiples usuarios en servidor.
