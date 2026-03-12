import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'db/firestore_service.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  bool _splashFinished = false;

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
    final user = await FirestoreService.instance.getUserByUsername(username);
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      home: _splashFinished
          ? (_currentUser == null
          ? LoginScreen(onLogin: _onLogin, onToggleTheme: _toggleTheme, isDark: _themeMode == ThemeMode.dark)
          : FeedScreen(currentUser: _currentUser!, onLogout: _onLogout, onToggleTheme: _toggleTheme))
          : SplashScreen(onFinish: () {
        setState(() {
          _splashFinished = true;
        });
      }),
      routes: {
        '/create': (_) => CreatePostScreen(currentUser: _currentUser!),
        '/profile': (_) => ProfileScreen(currentUser: _currentUser!),
        '/settings': (_) => SettingsScreen(onToggleTheme: _toggleTheme, onSetLanguage: _setLanguage, onLogout: _onLogout),
      },
    );
  }
}
