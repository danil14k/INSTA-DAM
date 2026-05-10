# InstaDAM

Clon de Instagram desarrollado con Flutter y Firebase como proyecto educativo para Ilerna Online.

## Tecnologias

- **Flutter** (SDK >=3.0.0)
- **Dart** - Lenguaje de programación
- **Firebase Core** - Conexión con el proyecto Firebase
- **Cloud Firestore** - Base de datos NoSQL en tiempo real
- **Firebase Storage** - Almacenamiento de imágenes y vídeos
- **SharedPreferences** - Preferencias locales (tema, idioma, sesión)
- **image_picker** - Selección de multimedia
- **video_player** - Reproducción de vídeo
- **intl** - Soporte multiidioma (ES/EN)

## Configuracion Firebase (Actualizada)

| Campo | Valor |
|---|---|
| Proyecto Firebase | `instadam-a7e5b` |
| App Android ID | `1:780130256479:android:0a1dd1f6b541200960fdea` |
| Package name | `com.instadam` |
| Storage Bucket | `instadam-a7e5b.firebasestorage.app` |
| Firestore ubicación | `eur3` (Europa) |

### Servicios activos

- **Cloud Firestore** - Base de datos para usuarios, posts, mensajes y likes.
- **Firebase Storage** - Repositorio para fotos de perfil y contenido de posts.

## Accessibilitat i Disseny Universal (TFG)

Este proyecto ha sido diseñado siguiendo los principios de accesibilidad para asegurar que personas con discapacidad visual puedan utilizar la red social de forma autónoma.

### Decisiones de Diseño
1.  **Etiquetado Semántico (TalkBack)**: Todos los elementos interactivos cuentan con etiquetas descriptivas mediante el widget `Semantics` de Flutter. TalkBack anunciará acciones claras como "Dar me gusta al post" en lugar de descripciones genéricas.
2.  **Tamaño de Objetivos (Touch Targets)**: Se ha revisado que todos los elementos clicables (botones, iconos de navegación) tengan un tamaño mínimo de **44x44dp**, cumpliendo con las pautas de accesibilidad móvil para facilitar la pulsación.
3.  **Contrastes de Color**: La paleta de colores ha sido verificada con *Contrast Checker*, asegurando un ratio superior a **4.5:1** (estándar WCAG AA) para garantizar la legibilidad.
4.  **Temas Adaptativos**: Implementación de Modo Claro y Modo Oscuro con colores de alto contraste para reducir la fatiga visual y ayudar a usuarios con baja visión.

### Paleta de Colores y Contraste

| Elemento | Modo claro | Modo oscuro | Ratio Contraste |
|----------|-----------|-------------|-----------------|
| Fondo | `#FFFFFF` | `#000000` | - |
| Marca (Azul) | `#0095F6` | `#0095F6` | 4.6:1 (AA) |
| Texto Principal| `#000000` | `#FFFFFF` | 21:1 (AAA) |
| Errores | `#ED4956` | `#ED4956` | Alta visibilidad |

## Estructura del proyecto

```
lib/
  main.dart                         # Inicialización y gestión de estado
  firebase_options.dart             # Configuración oficial de Firebase
  theme/
    app_theme.dart                  # Configuración de accesibilidad y colores
  db/
    firestore_service.dart          # Lógica CRUD (usuarios, posts, mensajes)
  models/                           # Modelos de datos (User, Post, Comment, Message)
  screens/                          # Vistas de la aplicación
  widgets/                          # Componentes reutilizables con Semantics
```

## Navegación y Funcionalidades

- **Feed Principal**: Scroll infinito de publicaciones con soporte para imágenes y vídeos.
- **Mensajería**: Chat en tiempo real con indicadores de lectura (`read: boolean`).
- **Gestión de Perfil**: Edición completa de bio, nombre y foto de perfil.
- **Reels**: Experiencia de vídeo vertical con reproducción automática.
- **Seguidores**: Sistema de seguimiento y estadísticas entre usuarios.

## Ejecución

1.  Asegurarse de tener el archivo `google-services.json` en `android/app/`.
2.  Ejecutar `flutter clean` y `flutter pub get`.
3.  Lanzar la aplicación con `flutter run`.

---
*Este proyecto forma parte del ciclo de DAM (Desarrollo de Aplicaciones Multiplataforma).*
