import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'db/database_helper.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init();
  final prefs = await SharedPreferences.getInstance();
  final remembered = prefs.getBool('remembered') ?? false;
  final username = prefs.getString('username');
  runApp(MyApp(startRemembered: remembered, username: username));
}

class MyApp extends StatefulWidget {
  final bool startRemembered;
  final String? username;
  MyApp({required this.startRemembered, this.username});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = Locale('en');
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    if (widget.startRemembered && widget.username != null) {
      _loadUser(widget.username!);
    }
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('darkTheme') ?? false;
    final lang = prefs.getString('language') ?? 'en';
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
      _locale = Locale(lang);
    });
  }

  void _loadUser(String username) async {
    final user = await DatabaseHelper.instance.getUserByUsername(username);
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogin(User user, {bool remember = false}) async {
    if (remember) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remembered', true);
      await prefs.setString('username', user.username);
    }
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _currentUser = null;
    });
  }

  void _toggleTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', dark);
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
    setState(() {
      _locale = Locale(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstaDAM',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      locale: _locale,
      home: _currentUser == null ? LoginScreen(onLogin: _onLogin) : FeedScreen(currentUser: _currentUser!, onLogout: _onLogout),
      routes: {
        '/create': (_) => CreatePostScreen(currentUser: _currentUser!),
        '/profile': (_) => ProfileScreen(currentUser: _currentUser!),
        '/settings': (_) => SettingsScreen(onToggleTheme: _toggleTheme, onSetLanguage: _setLanguage, onLogout: _onLogout),
      },
    );
  }
}
