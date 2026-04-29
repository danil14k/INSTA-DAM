import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/strings.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final Function(String) onSetLanguage;
  final VoidCallback onLogout;

  SettingsScreen({
    required this.onToggleTheme,
    required this.onSetLanguage,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dark = false;
  bool _notifs = true;
  String _lang = 'es';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dark = prefs.getBool('darkTheme') ?? false;
      _lang = prefs.getString('language') ?? 'es';
      _notifs = prefs.getBool('notifs') ?? true;
    });
  }

  void _saveNotifs(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifs', v);
    setState(() => _notifs = v);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(v ? 'Notificaciones activadas' : 'Notificaciones desactivadas'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(Strings.t(context, 'logout_title') ?? 'Cerrar sesión'),
          content: Text(Strings.t(context, 'logout_confirm') ?? '¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: Text(Strings.t(context, 'cancel') ?? 'Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                Strings.t(context, 'logout') ?? 'Cerrar sesión',
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onLogout();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.t(context, 'select_language') ?? 'Seleccionar idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              leading: Radio<String>(
                value: 'es',
                groupValue: _lang,
                onChanged: (v) {
                  if (v != null) {
                    widget.onSetLanguage(v);
                    setState(() => _lang = v);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                widget.onSetLanguage('es');
                setState(() => _lang = 'es');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: _lang,
                onChanged: (v) {
                  if (v != null) {
                    widget.onSetLanguage(v);
                    setState(() => _lang = v);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                widget.onSetLanguage('en');
                setState(() => _lang = 'en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Strings.t(context, 'settings'), 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver a la pantalla anterior',
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Apariencia y Accesibilidad'),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: isDark ? AppTheme.igBlue : AppTheme.igGrey),
            title: Text(Strings.t(context, 'dark_theme')),
            subtitle: Text(isDark ? 'Activado' : 'Desactivado'),
            value: _dark,
            onChanged: (v) {
              setState(() => _dark = v);
              widget.onToggleTheme(v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(Strings.t(context, 'language')),
            subtitle: Text(_lang == 'en' ? 'English' : 'Español'),
            onTap: _showLanguageDialog,
          ),
          
          _buildSectionHeader(context, 'Notificaciones'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none),
            title: Text(Strings.t(context, 'notifs')),
            subtitle: Text(_notifs ? 'Activadas' : 'Desactivadas'),
            value: _notifs,
            onChanged: _saveNotifs,
          ),

          _buildSectionHeader(context, 'Información'),
          _buildSettingsItem(
            context, 
            icon: Icons.info_outline, 
            title: 'Acerca de InstaDAM', 
            onTap: () {}
          ),
          _buildSettingsItem(
            context, 
            icon: Icons.help_outline, 
            title: 'Ayuda y soporte técnico', 
            onTap: () {}
          ),
          
          const Divider(height: 32),
          
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.igRed),
            title: Text(
              Strings.t(context, 'logout'), 
              style: const TextStyle(color: AppTheme.igRed, fontWeight: FontWeight.bold)
            ),
            onTap: _showLogoutConfirmation,
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Versión 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.igGrey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.igGrey),
      onTap: onTap,
    );
  }
}
