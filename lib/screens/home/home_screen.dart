import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../api/nutrition_api.dart';
import '../../services/health_service.dart';
import '../../models/meal.dart';

import 'package:nutrifit_ai_app/services/auth_service.dart';
import 'package:nutrifit_ai_app/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "пользователь";
  int _todayCalories = 0;
  int _calorieGoal = 2200;
  int _todaySteps = 0;
  int? _heartRate;
  int _sleepMinutes = 0;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDashboardData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadUserName() async {
    final name = await StorageService.getProfileName();
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name;
      });
    }

    // Update from API in background to ensure freshness
    try {
      final profile = await AuthService().getProfile();
      if (profile != null && profile['fullName'] != null) {
        if (mounted) {
          setState(() {
            _userName = profile['fullName'].toString();
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final nutritionApi = NutritionApi();
      final meals = await nutritionApi.getMeals();
      final today = DateTime.now();
      int totalCalories = 0;
      for (final meal in meals) {
        if (meal.mealDate.year == today.year &&
            meal.mealDate.month == today.month &&
            meal.mealDate.day == today.day) {
          totalCalories += meal.totalCalories.round();
        }
      }

      try {
        final goals = await nutritionApi.getGoals();
        if (goals != null && goals['dailyCalories'] != null) {
          _calorieGoal = (goals['dailyCalories'] as num).round();
        }
      } catch (_) {}

      int steps = 0;
      int? heartRate;
      int sleepMins = 0;
      try {
        final healthService = HealthService();
        await healthService.configure();
        final hasPerms = await healthService.hasPermissions();
        if (hasPerms) {
          steps = await healthService.getTodaySteps();
          heartRate = await healthService.getLatestHeartRate();
          sleepMins = await healthService.getTodaySleep();
        }
      } catch (e) {
        print('Health data on dashboard: $e');
      }

      if (mounted) {
        setState(() {
          _todayCalories = totalCalories;
          _todaySteps = steps;
          _heartRate = heartRate;
          _sleepMinutes = sleepMins;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriFit AI"),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/profile"),
            icon: const Icon(Icons.person_outline),
            tooltip: "Профиль",
          ),
        ],
      ),
      body: Stack(
        children: [
          // фоновой градиент
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.heroGradient,
              ),
            ),
          ),
          // контент
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildHighlights(),
                  const SizedBox(height: 16),
                  _buildDailyMetrics(context),
                  const SizedBox(height: 18),
                  _buildQuickActions(context),
                  const SizedBox(height: 18),
                  _buildSections(context),
                  const SizedBox(height: 24),
                  _buildAiAssistantButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F2540),
            Color(0xFF0F1324),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDarker,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Добро пожаловать, $_userName 👋",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Твой персональный помощник по питанию и тренировкам",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _highlightTile(
            title: "Калории",
            value: "$_todayCalories / $_calorieGoal",
            subtitle: "${(_calorieGoal - _todayCalories).clamp(0, 99999)} ккал осталось",
            icon: Icons.local_fire_department,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _highlightTile(
            title: "Шаги",
            value: "$_todaySteps",
            subtitle: "${(10000 - _todaySteps).clamp(0, 99999)} до цели",
            icon: Icons.directions_walk,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _highlightTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        height: 155,
        decoration: BoxDecoration(
          color: AppColors.cardDarker,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMetrics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              "Сегодня",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.bolt, color: AppColors.secondary, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bedtime, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _sleepMinutes > 0 ? "${_sleepMinutes ~/ 60} ч ${_sleepMinutes % 60} мин" : "— ч",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text("Сон", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite, color: AppColors.error, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${_heartRate ?? '—'} уд/м",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text("Пульс", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Быстрые действия",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              Icon(Icons.flash_on, color: AppColors.secondary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionChip(
                  label: "Добавить приём пищи",
                  icon: Icons.restaurant_menu,
                  onTap: () => Navigator.pushNamed(context, "/nutrition"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionChip(
                  label: "Записать тренировку",
                  icon: Icons.fitness_center,
                  onTap: () => Navigator.pushNamed(context, "/workouts"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _quickActionChip(
              label: "Спросить AI",
              icon: Icons.bubble_chart_outlined,
              onTap: () => Navigator.pushNamed(context, "/ai"),
              fill: AppColors.primary.withOpacity(0.12),
              iconColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? fill,
    Color? iconColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: fill ?? AppColors.cardDarker,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSections(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      padding: EdgeInsets.zero,
      children: [
        _sectionTile(
          title: "Питание",
          icon: Icons.restaurant_menu,
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, "/nutrition"),
        ),
        _sectionTile(
          title: "Тренировки",
          icon: Icons.fitness_center,
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, "/workouts"),
        ),
        _sectionTile(
          title: "Здоровье",
          icon: Icons.monitor_heart,
          color: AppColors.warning,
          onTap: () => Navigator.pushNamed(context, "/metrics"),
        ),
        _sectionTile(
          title: "Смарт-часы",
          icon: Icons.watch,
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamed(context, "/smartwatch"),
        ),
        _sectionTile(
          title: "Профиль",
          icon: Icons.person,
          color: AppColors.textSecondary,
          onTap: () => Navigator.pushNamed(context, "/profile"),
        ),
      ],
    );
  }

  Widget _sectionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Открыть подробнее",
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAssistantButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, "/ai"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Открыть AI ассистента",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Персональные рекомендации в один клик",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              backgroundColor: Colors.white12,
              child: Icon(Icons.bolt, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
