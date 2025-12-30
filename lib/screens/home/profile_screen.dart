import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/storage_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Mukhammedali";
  String _height = "177";
  String _weight = "63";
  String _age = "19";
  String _activity = "3 тренировки в неделю";
  String _goal = "Набрать массу до 70 кг";

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
      _name = name;
      _height = height;
      _weight = weight;
      _age = age;
      _activity = activity;
      _goal = goal;
    });
  }

  void _logout(BuildContext context) async {
    await StorageService.clearToken();
    Navigator.pushReplacementNamed(context, "/login");
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (result == true) {
      _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Профиль"),
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
          child: Column(
            children: [
              _headerCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _statPill("$_height см", "Рост")),
                  const SizedBox(width: 10),
                  Expanded(child: _statPill("$_weight кг", "Вес")),
                  const SizedBox(width: 10),
                  Expanded(child: _statPill("$_age лет", "Возраст")),
                ],
              ),
              const SizedBox(height: 18),
              _infoTile("Цель", _goal, Icons.flag),
              const SizedBox(height: 12),
              _infoTile("Активность", _activity, Icons.run_circle),
              const SizedBox(height: 24),
              _settingsTile("Язык приложения", Icons.language),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Выйти", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 48, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Профиль и параметры здоровья",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.edit, color: AppColors.textSecondary),
            tooltip: "Редактировать",
          ),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDarker,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
        ],
      ),
    );
  }
}
