import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../utils/strings.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final Function(User user, {bool remember}) onLogin;
  final Function(bool) onToggleTheme;
  final bool isDark;
  LoginScreen({required this.onLogin, required this.onToggleTheme, required this.isDark});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _remember = false;

  void _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    var user = await DatabaseHelper.instance.login(username, password);
    if (user == null) {
      final existing = await DatabaseHelper.instance.getUserByUsername(username);
      if (existing == null) {
        user = await DatabaseHelper.instance.createUser(User(username: username, password: password, displayName: username));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid password')));
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', user.displayName ?? user.username);
    widget.onLogin(user, remember: _remember);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = AppTheme.brandOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      isDark
                          ? 'assets/media/logos/logo_negro.png'
                          : 'assets/media/logos/logo_blanco.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'InstaDAM',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 40),
                  TextField(
                    controller: _userCtrl,
                    decoration: InputDecoration(
                      hintText: Strings.t(context, 'username_label'),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      hintText: Strings.t(context, 'password_label'),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(value: _remember, onChanged: (v) => setState(() => _remember = v ?? false)),
                      Text(Strings.t(context, 'remember')),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: Text(Strings.t(context, 'enter'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 40),
                  Divider(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      Text("Sign up.", style: TextStyle(color: brand, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Theme toggle button - always visible
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: brand),
              onPressed: () => widget.onToggleTheme(!isDark),
              tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            ),
          ),
        ],
      ),
    );
  }
}
