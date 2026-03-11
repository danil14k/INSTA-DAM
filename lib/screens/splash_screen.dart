import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startNavigationTimer();
    _announceLoading();
  }

  void _announceLoading() {
    // TalkBack: Announce "Carregant aplicació"
    Future.delayed(Duration.zero, () {
      SemanticsService.announce('Carregant aplicació', TextDirection.ltr);
    });
  }

  void _startNavigationTimer() {
    Timer(const Duration(seconds: 3), () {
      widget.onFinish();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Accessible Logo
            Semantics(
              label: 'InstaDAM logo',
              image: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/media/logos/logo_negro.png'
                      : 'assets/media/logos/logo_blanco.png',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // State change announcement (Live region)
            Semantics(
              liveRegion: true,
              label: 'L\'aplicació s\'està carregant',
              child: const CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
