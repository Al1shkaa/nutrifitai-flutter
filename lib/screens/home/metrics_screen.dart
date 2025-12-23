import 'package:flutter/material.dart';
import '../../data/demo_metrics.dart';
import '../../theme/app_colors.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Показатели здоровья"),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,           // 2 карточки в ряд
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),

        itemCount: demoMetrics.length,
        itemBuilder: (context, index) {
          final m = demoMetrics[index];

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconFromString(m.icon), size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    m.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.value,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.unit,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFromString(String iconName) {
    switch (iconName) {
      case "favorite":
        return Icons.favorite;
      case "directions_walk":
        return Icons.directions_walk;
      case "bedtime":
        return Icons.bedtime;
      case "monitor_weight":
        return Icons.monitor_weight;
      case "local_fire_department":
        return Icons.local_fire_department;
      default:
        return Icons.info;
    }
  }
}
