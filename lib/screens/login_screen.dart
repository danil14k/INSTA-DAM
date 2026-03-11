import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/user.dart';
import '../utils/strings.dart';

class LoginScreen extends StatefulWidget {
  final Function(User user, {bool remember}) onLogin;
  LoginScreen({required this.onLogin});

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
      // Simple auto-register for demo if user doesn't exist at all
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'InstaDAM',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _userCtrl,
                decoration: InputDecoration(
                  hintText: Strings.t(context, 'username_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  hintText: Strings.t(context, 'password_label'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(Strings.t(context, 'enter'), style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 40),
              Divider(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                  Text("Sign up.", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
