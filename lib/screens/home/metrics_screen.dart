import 'package:flutter/material.dart';
import '../../data/demo_metrics.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Показатели здоровья"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 8,
                )
              ],
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconFromString(m.icon), size: 40, color: Colors.blue),
                  const SizedBox(height: 10),

                  Text(
                    m.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    m.value,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),

                  Text(
                    m.unit,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
