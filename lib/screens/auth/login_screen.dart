import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../api/onboarding_api.dart';
import '../../widgets/app_button.dart';
import '../../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
  }

  void login() async {
    setState(() => isLoading = true);

    final success = await authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {
      // После успешного логина, проверяем статус профиля
      final onboardingStatus = await _checkProfileCompletion();
      
      if (mounted) {
        if (onboardingStatus['completed'] == true) {
          // Профиль полный - идём на home
          Navigator.pushReplacementNamed(context, "/home");
        } else {
          // Профиль неполный - идём на onboarding
          Navigator.pushReplacementNamed(context, "/onboarding");
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ошибка входа")),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _checkProfileCompletion() async {
    try {
      final onboardingApi = OnboardingApi();
      final status = await onboardingApi.getStatus();
      print('Profile completion status: $status');
      return status;
    } catch (e) {
      print('Error checking profile: $e');
      return {'completed': false};
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Зайди, чтобы получить персональные рекомендации",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.cardDarker,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Пароль",
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.cardDarker,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
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
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Нет аккаунта? ",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, "/register"),
                              child: const Text(
                                "Зарегистрироваться",
                                style: TextStyle(
                                  color: AppColors.primary,
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
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
