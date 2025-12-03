import 'package:flutter/material.dart';
import '../../models/workout.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final List<Workout> workouts = [
    Workout(type: "Бег", duration: 30, calories: 250, time: "07:40"),
    Workout(type: "Тренажерный зал", duration: 60, calories: 520, time: "12:30"),
  ];

  void addWorkout(Workout workout) {
    setState(() => workouts.add(workout));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Тренировки"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final w = workouts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.fitness_center, size: 32),
              title: Text(w.type),
              subtitle: Text(
                "${w.duration} мин • ${w.calories} ккал • ${w.time}",
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _addWorkoutBottomSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addWorkoutBottomSheet(BuildContext context) {
    final typeController = TextEditingController();
    final durationController = TextEditingController();
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
              "Добавить тренировку",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: "Тип тренировки (бег, жим, кардио...)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Продолжительность (мин)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Сожжённые калории",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                addWorkout(
                  Workout(
                    type: typeController.text,
                    duration: int.tryParse(durationController.text) ?? 0,
                    calories: int.tryParse(caloriesController.text) ?? 0,
                    time:
                    "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
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
