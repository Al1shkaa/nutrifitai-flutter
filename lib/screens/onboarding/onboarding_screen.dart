import 'package:flutter/material.dart';
import '../../api/onboarding_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../utils/value_mappers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnboardingApi _api = OnboardingApi();
  
  // Form fields
  final nameController = TextEditingController();
  String? selectedGender;
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final ageController = TextEditingController();
  String? selectedGoal;

  bool isLoading = false;
  int currentStep = 0;
  double progress = 0.0;

  final genderOptions = ['Мужской', 'Женский'];
  final goalOptions = ['Похудеть', 'Набрать мышцы', 'Улучшить здоровье'];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _api.getStatus();
      if (mounted) {
        setState(() {
          progress = (status['progress'] as num?)?.toDouble() ?? 0.0;
          final completed = status['completed'] as bool? ?? false;
          if (!completed) {
            currentStep = 0;
            progress = 0.0;
          } else {
            final nextStep = status['nextStep'] as String? ?? 'GENDER';
            currentStep = _getStepIndex(nextStep);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки статуса: $e')),
        );
      }
    }
  }

  int _getStepIndex(String step) {
    switch (step) {
      case 'NAME':
      case 'name':
        return 0;
      case 'GENDER':
      case 'gender':
        return 1;
      case 'WEIGHT':
      case 'weight':
        return 2;
      case 'HEIGHT_CM':
      case 'HEIGHT':
      case 'height_cm':
      case 'height':
        return 3;
      case 'AGE':
      case 'age':
        return 4;
      case 'GOAL':
      case 'goal':
        return 5;
      default:
        return 0;
    }
  }

  String _getStepName(int step) {
    switch (step) {
      case 0:
        return 'fullName';
      case 1:
        return 'gender';
      case 2:
        return 'weight';
      case 3:
        return 'height';
      case 4:
        return 'age';
      case 5:
        return 'goal';
      default:
        return 'fullName';
    }
  }

  Future<void> _nextStep() async {
    if (!_validateCurrentStep()) {
      String errorMessage = 'Пожалуйста, заполните все поля';
      
      switch (currentStep) {
        case 0:
          errorMessage = 'Пожалуйста, введите ваше имя';
          break;
        case 2:
          errorMessage = 'Вес должен быть от 1 до 300 кг';
          break;
        case 3:
          errorMessage = 'Рост должен быть от 1 до 250 см';
          break;
        case 4:
          errorMessage = 'Возраст должен быть от 1 до 150 лет';
          break;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final stepName = _getStepName(currentStep);
      dynamic value;

      switch (currentStep) {
        case 0: // Name
          value = nameController.text.trim();
          if (value.isEmpty) value = null;
          break;
        case 1: // Gender
          value = mapGenderToBackend(selectedGender!);
          print('DEBUG: Gender step - selectedGender: $selectedGender, mapped: $value');
          break;
        case 2: // Weight
          value = double.tryParse(weightController.text.trim());
          print('DEBUG: Weight step - value: $value, type: ${value.runtimeType}');
          break;
        case 3: // Height
          value = double.tryParse(heightController.text.trim());
          print('DEBUG: Height step - text: "${heightController.text}", double: $value');
          break;
        case 4: // Age
          value = int.tryParse(ageController.text.trim());
          print('DEBUG: Age step - ageController.text: "${ageController.text}"');
          print('DEBUG: Age step - parsed value: $value');
          break;
        case 5: // Goal
          value = mapGoalToBackend(selectedGoal!);
          print('DEBUG: Goal step - selectedGoal: $selectedGoal, mapped: $value');
          break;
      }

      if (value == null) {
        throw Exception('Ошибка обработки значения');
      }

      final success = await _api.updateField(stepName, value);

      print('DEBUG: updateField called - step: $currentStep, field: $stepName, value: $value, success: $success');

      if (success) {
        if (currentStep < 5) {
          setState(() => currentStep++);
          _updateProgress();
        } else {
          // All steps completed, mark as complete
          await _completeOnboarding();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при сохранении данных. Пожалуйста, проверьте интернет и попробуйте снова.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final success = await _api.complete();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка при завершении. Попробуйте снова.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка завершения: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return nameController.text.trim().isNotEmpty;
      case 1:
        return selectedGender != null;
      case 2:
        final weight = double.tryParse(weightController.text.trim());
        return weight != null && weight > 0 && weight <= 300;
      case 3:
        final height = double.tryParse(heightController.text.trim());
        return height != null && height > 0 && height <= 250;
      case 4:
        final age = int.tryParse(ageController.text.trim());
        return age != null && age > 0 && age <= 150;
      case 5:
        return selectedGoal != null;
      default:
        return false;
    }
  }

  void _updateProgress() {
    setState(() {
      progress = (currentStep + 1) / 6.0;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    heightController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Завершение профиля'),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Text(
                  'Расскажи о себе',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Шаг ${currentStep + 1} из 6',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStepContent(),
                const SizedBox(height: 32),
                AppButton(
                  title: currentStep == 5 ? 'Завершить' : 'Далее',
                  onPressed: _nextStep,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildWeightStep();
      case 3:
        return _buildHeightStep();
      case 4:
        return _buildAgeStep();
      case 5:
        return _buildGoalStep();
      default:
        return Container();
    }
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Как тебя зовут?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Введите ваше имя",
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
      ],
    );
  }

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Какой у тебя пол?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        ...genderOptions.map((gender) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => selectedGender = gender),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedGender == gender
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedGender == gender
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedGender == gender
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: selectedGender == gender
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    gender,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildWeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Какой у тебя вес?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: weightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Вес в килограммах",
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
        const SizedBox(height: 12),
        const Text(
          'Введите вес в килограммах (1-300)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Какой у тебя рост?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: heightController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Рост в сантиметрах",
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
        const SizedBox(height: 12),
        const Text(
          'Введите рост в сантиметрах (1-250)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сколько тебе лет?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: ageController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Возраст в годах",
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
        const SizedBox(height: 12),
        const Text(
          'Введите возраст в годах (1-150)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Какая у тебя цель?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        ...goalOptions.map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => selectedGoal = goal),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedGoal == goal
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedGoal == goal
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedGoal == goal
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: selectedGoal == goal
                        ? const Center(
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    goal,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}
