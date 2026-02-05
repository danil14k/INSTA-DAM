import 'package:flutter/widgets.dart';

class Strings {
  static const _en = {
    'app_title': 'InstaDAM',
    'login_title': 'InstaDAM - Login',
    'username_label': 'Username',
    'display_label': 'Display name (optional)',
    'password_label': 'Password',
    'remember': 'Remember me',
    'enter': 'Sign in / Register',
    'feed_no_posts': 'No posts yet. Create your first!',
    'create_post': 'Create Post',
    'comments': 'Comments',
    'profile': 'Profile',
    'settings': 'Settings',
    'dark_theme': 'Dark theme',
    'notifs': 'Notifications (simulated)',
    'language': 'Language',
    'logout': 'Log out',
    'add_comment': 'Add comment',
    'publish': 'Publish',
    'edit_name': 'Edit name',
    'cancel': 'Cancel',
    'save': 'Save',
  };

  static const _es = {
    'app_title': 'InstaDAM',
    'login_title': 'InstaDAM - Login',
    'username_label': 'Nombre de usuario',
    'display_label': 'Nombre para mostrar (opcional)',
    'password_label': 'Contraseña',
    'remember': 'Recordarme',
    'enter': 'Entrar / Registrar',
    'feed_no_posts': 'Aún no hay posts. ¡Crea el primero!',
    'create_post': 'Crear Post',
    'comments': 'Comentarios',
    'profile': 'Perfil',
    'settings': 'Ajustes',
    'dark_theme': 'Tema oscuro',
    'notifs': 'Notificaciones (simulado)',
    'language': 'Idioma',
    'logout': 'Cerrar sesión',
    'add_comment': 'Añadir comentario',
    'publish': 'Publicar',
    'edit_name': 'Editar nombre',
    'cancel': 'Cancelar',
    'save': 'Guardar',
  };

  static String t(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'es') return _es[key] ?? key;
    return _en[key] ?? key;
  }
}
