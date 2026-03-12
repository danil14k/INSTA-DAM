# InstaDAM

Clon de Instagram desarrollado con Flutter como proyecto educativo.

## Tecnologias

- **Flutter** (SDK >=2.19.0)
- **Firebase Core** - Conexion con el proyecto Firebase
- **Cloud Firestore** - Base de datos en la nube (reemplaza SQLite)
- **Firebase Storage** - Almacenamiento de imagenes y videos en la nube
- **SharedPreferences** - Preferencias locales (tema, idioma, sesion)
- **image_picker** - Seleccion de fotos y videos
- **video_player** - Reproduccion de videos
- **intl** - Soporte multiidioma (ES/EN)

## Configuracion Firebase

| Campo | Valor |
|---|---|
| Proyecto Firebase | `instadam-420cc` |
| App Android ID | `1:786024455780:android:cb21aec640a79025c78971` |
| Package name | `com.example.instadam_grupo10` |
| Firestore ubicacion | `eur3` |
| Plan | Spark (gratuito) |

### Servicios activos

- **Cloud Firestore** - Modo de prueba (lectura/escritura libre)
- **Firebase Storage** - Para subida de imagenes de perfil y posts

### Colecciones Firestore

**usuarios**
- `username` (string), `password` (string), `displayName` (string), `bio` (string), `profileImagePath` (string)

**posts**
- `username` (string), `imageUrl` (string), `description` (string), `date` (string), `likes` (number), `mediaPath` (string), `mediaType` (string), `location` (string)

**comentarios**
- `postId` (string), `username` (string), `text` (string), `date` (string)

**likes**
- `postId` (string), `username` (string)
- Documento ID: `{postId}_{username}`

**follows**
- `followerUsername` (string), `followingUsername` (string)
- Documento ID: `{follower}_{following}`

**messages**
- `senderUsername` (string), `receiverUsername` (string), `text` (string), `date` (string), `read` (boolean)

**bookmarks**
- `postId` (string), `username` (string)
- Documento ID: `{postId}_{username}`

## Estructura del proyecto

```
lib/
  main.dart                         # Punto de entrada, inicializacion Firebase
  firebase_options.dart             # Configuracion auto-generada por FlutterFire CLI
  theme/
    app_theme.dart                  # Tema claro/oscuro
  db/
    firestore_service.dart          # Servicio principal Firestore (reemplaza SQLite)
    storage_service.dart            # Servicio Firebase Storage para subida de archivos
    database_helper.dart            # (Legacy) SQLite helper - ya no se usa
  models/
    user.dart                       # Modelo de usuario
    post.dart                       # Modelo de publicacion
    comment.dart                    # Modelo de comentario
    message.dart                    # Modelo de mensaje
  screens/
    splash_screen.dart              # Pantalla de carga inicial
    login_screen.dart               # Login / registro automatico
    feed_screen.dart                # Feed principal con navegacion inferior
    create_post_screen.dart         # Crear publicacion (foto/video + ubicacion + menciones)
    profile_screen.dart             # Perfil del usuario actual
    edit_profile_screen.dart        # Editar perfil (nombre, bio, foto)
    user_profile_screen.dart        # Perfil de otros usuarios (seguir/mensaje)
    settings_screen.dart            # Ajustes (tema, idioma, cerrar sesion)
    chat_list_screen.dart           # Lista de conversaciones
    chat_screen.dart                # Chat individual
    comments_screen.dart            # Comentarios de un post
    reels_screen.dart               # Reels (scroll vertical de videos)
    location_picker_screen.dart     # Selector de ubicacion
    mention_users_screen.dart       # Selector de usuarios para mencionar
  widgets/
    post_widget.dart                # Widget de publicacion con acciones
    mention_text.dart               # Texto con @menciones clicables
  utils/
    strings.dart                    # Traducciones ES/EN
```

## Funcionalidades

- Login / registro automatico de usuarios
- Feed de publicaciones con pull-to-refresh
- Crear posts con imagen/video, ubicacion y menciones
- Likes, comentarios y guardados (bookmarks)
- Seguir/dejar de seguir usuarios
- Perfiles con grid de posts, seguidores y seguidos
- Edicion de perfil (nombre, bio, foto de perfil)
- Chat privado entre usuarios con indicador de no leidos
- Reels (scroll vertical de contenido multimedia)
- Tema claro/oscuro persistente
- Soporte bilingue (Espanol / Ingles)
- Subida de imagenes a Firebase Storage

## Requisitos previos

1. Flutter SDK instalado
2. Android Studio con emulador o dispositivo fisico
3. Proyecto Firebase configurado (ya incluido en `firebase_options.dart`)
4. **Firebase Storage**: Activar en la consola de Firebase > Storage > Comenzar

## Ejecucion

```bash
flutter pub get
flutter run
```

## Notas importantes

- El archivo `database_helper.dart` es legacy y ya no se utiliza. Toda la logica de datos esta en `firestore_service.dart`.
- Firebase Storage debe estar activado en la consola de Firebase para que funcione la subida de imagenes. Si no esta activado, las imagenes se mantienen con rutas locales como fallback.
- Las reglas de Firestore estan en modo de prueba. Para produccion, configurar reglas de seguridad adecuadas.
- Firebase CLI se ejecuta con `npx firebase-tools` (no `firebase` directo) por problemas de PATH en Windows.
