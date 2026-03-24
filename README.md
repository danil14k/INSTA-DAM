# InstaDAM

Clon de Instagram desarrollado con Flutter y Firebase como proyecto educativo para Ilerna Online.

## Tecnologias

- **Flutter** (SDK >=2.19.0 <3.0.0)
- **Dart** - Lenguaje de programacion
- **Firebase Core** (v4.5.0) - Conexion con el proyecto Firebase
- **Cloud Firestore** (v6.1.3) - Base de datos en la nube
- **Firebase Storage** (v13.1.0) - Almacenamiento de imagenes y videos en la nube
- **SharedPreferences** (v2.1.1) - Preferencias locales (tema, idioma, sesion)
- **image_picker** (v1.0.4) - Seleccion de fotos y videos desde galeria o camara
- **video_player** (v2.8.1) - Reproduccion de videos con loop
- **intl** (v0.18.1) - Soporte multiidioma (ES/EN)
- **flutter_launcher_icons** (v0.13.1) - Generacion de iconos personalizados de la app

## Configuracion Firebase

| Campo | Valor |
|---|---|
| Proyecto Firebase | `instadam-420cc` |
| App Android ID | `1:786024455780:android:cb21aec640a79025c78971` |
| Package name | `com.example.instadam_grupo10` |
| Storage Bucket | `instadam-420cc.firebasestorage.app` |
| Firestore ubicacion | `eur3` (Europa) |
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
  main.dart                         # Punto de entrada, inicializacion Firebase, gestion de estado global
  firebase_options.dart             # Configuracion auto-generada por FlutterFire CLI
  theme/
    app_theme.dart                  # Tema claro/oscuro con paleta turquesa personalizada
  db/
    firestore_service.dart          # Servicio principal Firestore (singleton) - CRUD completo
    storage_service.dart            # Servicio Firebase Storage para subida de archivos (singleton)
    database_helper.dart            # (Legacy) SQLite helper - ya no se usa
  models/
    user.dart                       # Modelo de usuario (id, username, password, displayName, bio, profileImagePath)
    post.dart                       # Modelo de publicacion (con helpers: hasMedia, isVideo, isImage)
    comment.dart                    # Modelo de comentario
    message.dart                    # Modelo de mensaje (con campo read para estado de lectura)
  screens/
    splash_screen.dart              # Pantalla de carga inicial con animacion fade
    login_screen.dart               # Login / registro automatico con opcion "recuerdame"
    feed_screen.dart                # Pantalla principal con navegacion inferior (5 tabs)
    create_post_screen.dart         # Crear publicacion (foto/video + ubicacion + menciones)
    profile_screen.dart             # Perfil del usuario actual con grid de posts
    edit_profile_screen.dart        # Editar perfil (nombre, bio, username, foto)
    user_profile_screen.dart        # Perfil de otros usuarios (seguir/mensaje)
    settings_screen.dart            # Ajustes (tema, idioma, notificaciones, cerrar sesion)
    chat_list_screen.dart           # Lista de conversaciones con contador de no leidos
    chat_screen.dart                # Chat individual entre usuarios
    comments_screen.dart            # Comentarios de un post con fechas formateadas
    reels_screen.dart               # Reels (scroll vertical de videos con autoplay y loop)
    location_picker_screen.dart     # Selector de ubicacion (ciudades de Espana + ubicacion personalizada)
    mention_users_screen.dart       # Selector de usuarios para mencionar en posts
  widgets/
    post_widget.dart                # Widget de publicacion con acciones (like, bookmark, comentar, editar, eliminar)
    mention_text.dart               # Texto con @menciones clicables que navegan al perfil
  utils/
    strings.dart                    # Traducciones ES/EN con funcion Strings.t(context, key)
assets/
  media/
    logos/
      logo_blanco.png               # Logo para modo claro
      logo_negro.png                # Logo para modo oscuro
    profiles/                        # Almacenamiento local de imagenes de perfil
```

## Navegacion principal

La app usa un `BottomNavigationBar` con 5 tabs:

| Tab | Icono | Pantalla |
|-----|-------|----------|
| Inicio | `home` | Feed de publicaciones con pull-to-refresh |
| Mensajes | `chat_bubble_outline` | Lista de conversaciones (ChatListScreen) |
| Crear | `add_box_outlined` | Crear nueva publicacion (navegacion push) |
| Reels | `movie_outlined` | Scroll vertical de videos |
| Perfil | `person_outline` | Perfil del usuario actual |

## Funcionalidades

### Autenticacion
- Login con usuario y contraseña
- Registro automatico si el usuario no existe
- Opcion "Recuerdame" con persistencia via SharedPreferences
- Auto-login al abrir la app si el usuario fue recordado

### Feed y publicaciones
- Feed principal con todas las publicaciones ordenadas por fecha
- Pull-to-refresh para actualizar el feed
- Crear posts con imagen o video desde galeria/camara
- Añadir ubicacion (selector con ciudades de España + entrada personalizada)
- Mencionar usuarios (@usuario) con selector dedicado
- Editar y eliminar posts propios
- Subida de media a Firebase Storage

### Interacciones sociales
- Likes con contador sincronizado en Firestore
- Comentarios en publicaciones
- Guardados/Bookmarks de posts
- Seguir/dejar de seguir usuarios
- Contadores de seguidores y seguidos

### Perfiles
- Perfil propio con grid de posts y estadisticas
- Edicion de perfil: nombre, bio, username, foto de perfil
- Subida de foto de perfil a Firebase Storage
- Perfil de otros usuarios con acciones (seguir, enviar mensaje)
- Lista de seguidores y seguidos

### Mensajeria
- Chat privado entre usuarios
- Lista de conversaciones con ultimo mensaje
- Indicador de mensajes no leidos
- Marcado automatico como leido al abrir conversacion
- Busqueda de usuarios para iniciar nueva conversacion

### Reels
- Scroll vertical de contenido multimedia (videos)
- Reproduccion automatica con loop
- Paginacion de contenido

### Personalizacion
- Tema claro/oscuro con paleta turquesa personalizada (Light: #32B5C9, Dark: #40CDE2)
- Boton de cambio de tema en feed y login
- Persistencia del tema seleccionado
- Soporte bilingue: Español (por defecto) e Ingles
- Toggle de notificaciones en ajustes

### Paleta de colores

| Elemento | Modo claro | Modo oscuro |
|----------|-----------|-------------|
| Fondo | `#FFFFFF` | `#121212` |
| Superficie | `#F8F9FA` | `#1E1E1E` |
| Marca/Acento | `#32B5C9` | `#40CDE2` |
| Texto principal | `#1A1A1A` | `#E4E6EB` |
| Texto secundario | `#65676B` | `#B0B3B8` |
| Divisor | `#DBDBDB` | `#3E4042` |
| Error | `#D32F2F` | `#D32F2F` |

## Requisitos previos

1. Flutter SDK instalado (>=2.19.0 <3.0.0)
2. Android Studio con emulador o dispositivo fisico (API 21+)
3. Proyecto Firebase configurado (ya incluido en `firebase_options.dart`)
4. **Firebase Storage**: Activar en la consola de Firebase > Storage > Comenzar

## Ejecucion

```bash
flutter pub get
flutter run
```

## Generar iconos personalizados

```bash
flutter pub run flutter_launcher_icons
```

## Notas importantes

- El archivo `database_helper.dart` es legacy y ya no se utiliza. Toda la logica de datos esta en `firestore_service.dart` y `storage_service.dart`.
- Firebase Storage debe estar activado en la consola de Firebase para que funcione la subida de imagenes. Si no esta activado, las imagenes se mantienen con rutas locales como fallback.
- Las reglas de Firestore estan en modo de prueba. Para produccion, configurar reglas de seguridad adecuadas.
- Las contraseñas se almacenan en texto plano en Firestore (proyecto educativo, no produccion).
- Firebase CLI se ejecuta con `npx firebase-tools` (no `firebase` directo) por problemas de PATH en Windows.
- La app soporta multiplataforma (Android, iOS, Web, Windows, macOS, Linux) pero esta optimizada para Android.
