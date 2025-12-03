import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NutriFit AI"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),
            _buildHeader(),

            const SizedBox(height: 24),
            _buildDailyMetrics(context),

            const SizedBox(height: 24),
            _buildSections(context),

            const SizedBox(height: 32),
            _buildAiAssistantButton(context),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------
  Widget _buildHeader() {
    return const Text(
      "Добро пожаловать, Mukhammedali 👋",
      style: TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ----------------------------------------------------------
  // DAILY METRICS BLOCK (Calories / Steps / Water)
  // ----------------------------------------------------------
  Widget _buildDailyMetrics(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metricCard("Калории", "1450 / 2200", Icons.local_fire_department),
        _metricCard("Шаги", "6 240", Icons.directions_walk),
        _metricCard("Вода", "1.2 L", Icons.water_drop),
      ],
    );
  }

  Widget _metricCard(String name, String value, IconData icon) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTIONS (Nutrition / Workouts / Metrics)
  // ----------------------------------------------------------
  Widget _buildSections(BuildContext context) {
    return Column(
      children: [
        _sectionTile(
          title: "Питание",
          icon: Icons.restaurant_menu,
          onTap: () => Navigator.pushNamed(context, "/nutrition"),
        ),
        const SizedBox(height: 12),
        _sectionTile(
          title: "Тренировки",
          icon: Icons.fitness_center,
          onTap: () => Navigator.pushNamed(context, "/workouts"),
        ),
        const SizedBox(height: 12),
        _sectionTile(
          title: "Здоровье",
          icon: Icons.monitor_heart,
          onTap: () => Navigator.pushNamed(context, "/metrics"),
        ),
      ],
    );
  }

  Widget _sectionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // AI ASSISTANT BUTTON
  // ----------------------------------------------------------
  Widget _buildAiAssistantButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, "/ai"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Center(
        child: Text(
          "Открыть AI ассистента",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
