import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  final authService = AuthService();

  void login() async {
    setState(() => isLoading = true);

    final success = await authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка входа")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B0F1A),
              Color(0xFF0E1324),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "NutriFit AI",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Зайди, чтобы получить персональные рекомендации",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFB8C0CC)),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151C2F),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF24314A)),
                    ),
                    child: Column(
                      children: [
                        AppInput(
                          controller: emailController,
                          hint: "Email",
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          controller: passwordController,
                          hint: "Пароль",
                          obscure: true,
                        ),
                        const SizedBox(height: 22),
                        AppButton(
                          title: "Войти",
                          onPressed: login,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Забыли пароль?",
                            style: TextStyle(color: Color(0xFFB8C0CC)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Нет аккаунта? ",
                              style: TextStyle(color: Color(0xFFB8C0CC)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, "/register"),
                              child: const Text(
                                "Зарегистрироваться",
                                style: TextStyle(
                                  color: Color(0xFF9B5CFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Войдя, ты подтверждаешь согласие с политикой конфиденциальности",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF7C8598), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
