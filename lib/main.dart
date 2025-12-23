import 'package:flutter/material.dart';
import 'package:nutrifit_ai_app/screens/home/profile_screen.dart';
import 'theme/app_theme.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/nutrition_screen.dart';
import 'screens/home/workouts_screen.dart';
import 'screens/home/metrics_screen.dart';
import 'screens/home/ai_screen.dart';

void main() {
  runApp(const NutriFitApp());
}

class NutriFitApp extends StatelessWidget {
  const NutriFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: "/splash",
      routes: {
        "/splash": (_) => const SplashScreen(),
        "/login": (_) => const LoginScreen(),
        "/register": (_) => const RegisterScreen(),
        "/home": (_) => const HomeScreen(),
        "/profile": (_) => const ProfileScreen(),
        "/nutrition": (_) => const NutritionScreen(),
        "/workouts": (_) => const WorkoutsScreen(),
        "/metrics": (_) => const MetricsScreen(),
        "/ai": (_) => const AiScreen(),
      },
    );
  }
}
