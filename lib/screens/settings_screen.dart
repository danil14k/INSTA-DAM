import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/strings.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final Function(String) onSetLanguage;
  final VoidCallback onLogout;
  SettingsScreen({required this.onToggleTheme, required this.onSetLanguage, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dark = false;
  bool _notifs = true;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dark = prefs.getBool('darkTheme') ?? false;
      _lang = prefs.getString('language') ?? 'en';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.t(context, 'settings'), style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Account', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined),
            title: Text(Strings.t(context, 'dark_theme')),
            value: _dark,
            onChanged: (v) {
              setState(() => _dark = v);
              widget.onToggleTheme(v);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.notifications_none),
            title: Text(Strings.t(context, 'notifs')),
            value: _notifs,
            onChanged: _saveNotifs,
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text(Strings.t(context, 'language')),
            subtitle: Text(_lang == 'en' ? 'English' : 'Español'),
            trailing: DropdownButton<String>(
              value: _lang,
              underline: SizedBox(),
              items: [
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
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Help'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(Strings.t(context, 'logout'), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
