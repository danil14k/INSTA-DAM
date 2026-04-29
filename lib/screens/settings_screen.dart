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
        content: Text(Strings.t(context, v ? 'notif_on' : 'notif_off')),
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
          title: Text(Strings.t(context, 'logout_title')),
          content: Text(Strings.t(context, 'logout_confirm')),
          actions: <Widget>[
            TextButton(
              child: Text(Strings.t(context, 'cancel')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                Strings.t(context, 'logout'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
        title: Text(Strings.t(context, 'select_language')),
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
          tooltip: Strings.t(context, 'back_tooltip'),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, Strings.t(context, 'appearance')),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: isDark ? AppTheme.igBlue : AppTheme.igGrey),
            title: Text(Strings.t(context, 'dark_theme')),
            subtitle: Text(isDark ? Strings.t(context, 'activated') : Strings.t(context, 'disabled')),
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
          
          _buildSectionHeader(context, Strings.t(context, 'notifications_section')),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_none),
            title: Text(Strings.t(context, 'notifs')),
            subtitle: Text(_notifs ? Strings.t(context, 'activated') : Strings.t(context, 'disabled')),
            value: _notifs,
            onChanged: _saveNotifs,
          ),

          _buildSectionHeader(context, Strings.t(context, 'info_section')),
          _buildSettingsItem(
            context, 
            icon: Icons.info_outline, 
            title: Strings.t(context, 'about'), 
            onTap: () {}
          ),
          _buildSettingsItem(
            context, 
            icon: Icons.help_outline, 
            title: Strings.t(context, 'help'), 
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
