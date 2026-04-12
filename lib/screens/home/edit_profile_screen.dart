import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../utils/value_mappers.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  String _selectedGoal = "Похудеть";
  bool _isLoading = true;
  final _authService = AuthService();

  final List<String> _goals = [
    "Похудеть",
    "Набрать мышцы",
    "Улучшить здоровье",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    // Сначала пытаемся загрузить с бэкенда
    final profileData = await _authService.getProfile();
    
    String name, heightCm, weightKg, age, goal;
    
    if (profileData != null) {
      // Данные получены с бэкенда
      name = profileData['fullName']?.toString() ?? "";
      heightCm = profileData['heightCm']?.toString() ?? "";
      weightKg = profileData['weightKg']?.toString() ?? "";
      age = profileData['age']?.toString() ?? "";
      goal = mapGoalFromBackend(profileData['goal']?.toString() ?? "LOSE_WEIGHT");
    } else {
      // Если не удалось загрузить с бэкенда, используем локальные данные
      name = await StorageService.getProfileName() ?? "";
      heightCm = await StorageService.getProfileHeight() ?? "";
      weightKg = await StorageService.getProfileWeight() ?? "";
      age = await StorageService.getProfileAge() ?? "";
      goal = mapGoalFromBackend(await StorageService.getProfileGoal() ?? "LOSE_WEIGHT");
    }

    setState(() {
      _nameController = TextEditingController(text: name);
      _heightController = TextEditingController(text: heightCm);
      _weightController = TextEditingController(text: weightKg);
      _ageController = TextEditingController(text: age);
      _selectedGoal = goal;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final weight = double.tryParse(_weightController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final age = int.tryParse(_ageController.text.trim());

      // Сохраняем на бэкенд
      final success = await _authService.updateProfile({
        'name': _nameController.text.trim(),
        'weight': weight,
        'height': height,
        'age': age,
        'goal': mapGoalToBackend(_selectedGoal),
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Профиль успешно сохранён"),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ошибка при сохранении профиля"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Редактирование профиля"),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.heroGradient,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Редактирование профиля"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.heroGradient,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("Основная информация"),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  label: "Имя",
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Введите имя";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: "Рост (см)",
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Введите рост";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label: "Вес (кг)",
                        icon: Icons.monitor_weight,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Введите вес";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ageController,
                  label: "Возраст",
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Введите возраст";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionTitle("Цель"),
                const SizedBox(height: 12),
                _buildGoalSelector(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Сохранить изменения",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildGoalSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.flag, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              "Цель",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _selectedGoal,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        children: _goals.map((goal) {
          return RadioListTile<String>(
            title: Text(goal, style: const TextStyle(color: AppColors.textPrimary)),
            value: goal,
            groupValue: _selectedGoal,
            onChanged: (value) {
              setState(() {
                _selectedGoal = value!;
              });
            },
            activeColor: AppColors.primary,
          );
        }).toList(),
      ),
    );
  }
}

