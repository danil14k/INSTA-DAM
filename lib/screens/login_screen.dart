import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/firestore_service.dart';
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
  final _passFocus = FocusNode();

  bool _remember = false;
  bool _loading = false;
  String? _error;

  void _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var user = await FirestoreService.instance.login(username, password);
      if (user == null) {
        final existing = await FirestoreService.instance.getUserByUsername(username);
        if (existing == null) {
          user = await FirestoreService.instance.createUser(User(username: username, password: password, displayName: username));
        } else {
          setState(() => _error = 'Contraseña incorrecta');
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', user.displayName ?? user.username);
      widget.onLogin(user, remember: _remember);
    } catch (e) {
      setState(() => _error = 'Ha ocurrido un error. Inténtalo de nuevo.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        isDark
                            ? 'assets/media/logos/logo_negro.png'
                            : 'assets/media/logos/logo_blanco.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: Text(
                      'InstaDAM',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Global Error Message
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_error != null) SizedBox(height: 16),

                  // Username Field
                  Text(Strings.t(context, 'username_label'), style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    controller: _userCtrl,
                    decoration: InputDecoration(
                      hintText: Strings.t(context, 'username_label'),
                      errorText: _userCtrl.text.isEmpty ? 'El nombre de usuario no puede estar vacío' : null,
                    ),
                    onSubmitted: (_) => _passFocus.requestFocus(),
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),

                  // Password Field
                  Text(Strings.t(context, 'password_label'), style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    focusNode: _passFocus,
                    decoration: InputDecoration(
                      hintText: Strings.t(context, 'password_label'),
                      errorText: _passCtrl.text.isEmpty ? 'La contraseña no puede estar vacía' : null,
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 8),

                  // Remember me Switch
                  Semantics(
                    toggled: _remember,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(Strings.t(context, 'remember'), style: TextStyle(fontSize: 16)),
                        Switch(value: _remember, onChanged: (v) => setState(() => _remember = v)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : Text(Strings.t(context, 'enter'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Divider(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("¿No tienes cuenta? ", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      Text("Regístrate.", style: TextStyle(color: brand, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Theme toggle button
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
