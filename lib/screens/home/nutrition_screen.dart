import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../theme/app_colors.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final List<Meal> meals = [
    Meal(name: "Овсянка с медом", calories: 320, time: "08:30"),
    Meal(name: "Куриная грудка + рис", calories: 450, time: "13:10"),
    Meal(name: "Йогурт + орехи", calories: 180, time: "16:00"),
  ];

  void addMeal(Meal meal) {
    setState(() => meals.add(meal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Дневник питания"),
      ),

      body: ListView.builder(
        itemCount: meals.length,
        itemBuilder: (context, index) {
          final meal = meals[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_menu, color: AppColors.primary),
              ),
              title: Text(
                meal.name,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "${meal.calories} ккал • ${meal.time}",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMealDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Добавить продукт",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Название",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Калории",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                addMeal(
                  Meal(
                    name: nameController.text,
                    calories: int.tryParse(caloriesController.text) ?? 0,
                    time: "${DateTime.now().hour}:${DateTime.now().minute}",
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Добавить"),
            ),
          ],
        ),
      ),
    );
  }
}
