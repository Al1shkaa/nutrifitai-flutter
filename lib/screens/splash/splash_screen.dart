import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 800)); // красивый переход

    final token = await StorageService.getToken();

    if (token != null && token.isNotEmpty) {
      // токен есть → сразу домой
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      // токена нет → на логин
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0F1A),
              Color(0xFF111728),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "NutriFit AI",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Загружаем персональные рекомендации...",
                style: TextStyle(color: Color(0xFFB8C0CC)),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  color: Color(0xFF9B5CFF),
                  strokeWidth: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
