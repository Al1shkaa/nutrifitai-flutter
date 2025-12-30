import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/storage_service.dart';

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
  late TextEditingController _activityController;
  String _selectedGoal = "Набрать массу до 70 кг";

  final List<String> _goals = [
    "Набрать массу до 70 кг",
    "Похудеть до 60 кг",
    "Поддержать текущий вес",
    "Набрать мышечную массу",
    "Улучшить выносливость",
    "Снизить процент жира",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final name = await StorageService.getProfileName() ?? "Mukhammedali";
    final height = await StorageService.getProfileHeight() ?? "177";
    final weight = await StorageService.getProfileWeight() ?? "63";
    final age = await StorageService.getProfileAge() ?? "19";
    final activity = await StorageService.getProfileActivity() ?? "3 тренировки в неделю";
    final goal = await StorageService.getProfileGoal() ?? "Набрать массу до 70 кг";

    setState(() {
      _nameController = TextEditingController(text: name);
      _heightController = TextEditingController(text: height);
      _weightController = TextEditingController(text: weight);
      _ageController = TextEditingController(text: age);
      _activityController = TextEditingController(text: activity);
      _selectedGoal = goal;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await StorageService.saveProfileName(_nameController.text);
      await StorageService.saveProfileHeight(_heightController.text);
      await StorageService.saveProfileWeight(_weightController.text);
      await StorageService.saveProfileAge(_ageController.text);
      await StorageService.saveProfileActivity(_activityController.text);
      await StorageService.saveProfileGoal(_selectedGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Профиль успешно сохранён"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildSectionTitle("Цель и активность"),
                const SizedBox(height: 12),
                _buildGoalSelector(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _activityController,
                  label: "Активность",
                  icon: Icons.run_circle,
                  hint: "Например: 3 тренировки в неделю",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Введите уровень активности";
                    }
                    return null;
                  },
                ),
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

