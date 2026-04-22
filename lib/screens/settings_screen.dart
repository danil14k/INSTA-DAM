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
  }

  void _logout() async {
    widget.onLogout();
    Navigator.of(context).popUntil((route) => route.isFirst);
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
          tooltip: 'Volver',
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Apariencia y Accesibilidad'),
          Semantics(
            label: 'Cambiar a tema ${isDark ? 'claro' : 'oscuro'}',
            hint: 'Activa o desactiva el modo oscuro de la aplicación',
            child: SwitchListTile(
              secondary: Icon(Icons.dark_mode_outlined, color: isDark ? AppTheme.igBlue : AppTheme.igGrey),
              title: Text(Strings.t(context, 'dark_theme')),
              value: _dark,
              onChanged: (v) {
                setState(() => _dark = v);
                widget.onToggleTheme(v);
              },
            ),
          ),
          _buildLanguageSelector(context),
          
          _buildSectionHeader(context, 'Notificaciones'),
          Semantics(
            label: 'Notificaciones de la aplicación',
            hint: 'Permite recibir avisos sobre nuevos likes y comentarios',
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
              title: Text(Strings.t(context, 'notifs')),
              value: _notifs,
              onChanged: _saveNotifs,
            ),
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
            onTap: _logout,
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'Versión 1.0.0 (Fase 1 Accessible)',
              style: TextStyle(color: AppTheme.igGrey, fontSize: 12),
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
        style: const TextStyle(
          color: AppTheme.igGrey,
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

  Widget _buildLanguageSelector(BuildContext context) {
    return Semantics(
      label: 'Seleccionar idioma',
      hint: 'Cambia el idioma de la interfaz de la aplicación',
      child: ListTile(
        leading: const Icon(Icons.language),
        title: Text(Strings.t(context, 'language')),
        subtitle: Text(_lang == 'en' ? 'English' : 'Español'),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _lang,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.igGrey),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'es', child: Text('Español')),
            ],
            onChanged: (v) {
              if (v != null) {
                widget.onSetLanguage(v);
                setState(() => _lang = v);
              }
            },
          ),
        ),
      ),
    );
  }
}
