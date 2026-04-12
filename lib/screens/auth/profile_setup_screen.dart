import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  String? selectedGender;
  String? selectedGoal;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final authService = AuthService();

  final genderOptions = ['Мужской', 'Женский'];
  final goalOptions = ['Похудеть', 'Набрать мышцы', 'Улучшить здоровье'];

  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите вес";
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0 || weight > 300) {
      return "Введите корректный вес (1-300 кг)";
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return "Введите рост";
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0 || height > 250) {
      return "Введите корректный рост (1-250 см)";
    }
    return null;
  }

  bool _validateCurrentStep() {
    if (selectedGender == null || selectedGender!.isEmpty) {
      return false;
    }

    final weight = double.tryParse(weightController.text.trim());
    if (weight == null || weight <= 0 || weight > 300) {
      return false;
    }

    final height = double.tryParse(heightController.text.trim());
    if (height == null || height <= 0 || height > 250) {
      return false;
    }

    if (selectedGoal == null || selectedGoal!.isEmpty) {
      return false;
    }

    return true;
  }

  void _continue() {
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, проверьте все поля")),
      );
      return;
    }

    // Сохраняем данные в локальное хранилище
    _saveProfileData();
  }

  Future<void> _saveProfileData() async {
    setState(() => isLoading = true);
    try {
      // Сохраняем локально все данные профиля
      final weight = weightController.text.trim();
      final height = heightController.text.trim();

      print('=== SAVING PROFILE LOCALLY ===');
      print('Weight: $weight');
      print('Height: $height');
      print('Gender: $selectedGender');
      print('Goal: $selectedGoal');

      // Проверка что данные не пусты
      if (weight.isEmpty) {
        throw Exception('Вес не может быть пустым');
      }
      if (height.isEmpty) {
        throw Exception('Рост не может быть пустым');
      }
      if (selectedGender == null || selectedGender!.isEmpty) {
        throw Exception('Пол не выбран');
      }
      if (selectedGoal == null || selectedGoal!.isEmpty) {
        throw Exception('Цель не выбрана');
      }

      // Сохраняем weight и height
      await StorageService.saveProfileWeight(weight);
      print('✓ Weight saved');

      await StorageService.saveProfileHeight(height);
      print('✓ Height saved');

      // Сохраняем gender и goal в SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("profile_gender", selectedGender!);
      print('✓ Gender saved: $selectedGender');

      await prefs.setString("profile_goal", selectedGoal!);
      print('✓ Goal saved: $selectedGoal');

      print('=== PROFILE SAVED LOCALLY ===');
      print('Go to login to sync with server');

      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Данные сохранены. Войдите в аккаунт для синхронизации"),
            duration: Duration(seconds: 2),
          ),
        );

        // Задержка перед переходом на логин
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/login");
        }
      }
    } catch (e) {
      print('ERROR saving profile: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка при сохранении: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Расскажи о себе",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Эти данные помогут нам подобрать идеальные рекомендации",
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
                          // Пол
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Пол",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: genderOptions.map((gender) {
                              final isSelected = selectedGender == gender;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => selectedGender = gender),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.2)
                                          : AppColors.cardDarker,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      gender,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Вес
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Вес (кг)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: weightController,
                            validator: _validateWeight,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: "Например: 75",
                              hintStyle:
                                  const TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.cardDarker,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Рост
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Рост (см)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: heightController,
                            validator: _validateHeight,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: "Например: 180",
                              hintStyle:
                                  const TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.cardDarker,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Цель
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Твоя цель",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...goalOptions.map((goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedGoal = goal),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selectedGoal == goal
                                      ? AppColors.primary.withOpacity(0.2)
                                      : AppColors.cardDarker,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedGoal == goal
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width:
                                        selectedGoal == goal ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  goal,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedGoal == goal
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontWeight: selectedGoal == goal
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          )),
                          const SizedBox(height: 22),
                          AppButton(
                            title: "Продолжить",
                            onPressed: _continue,
                            isLoading: isLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Ты всегда сможешь изменить эти данные позже",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
