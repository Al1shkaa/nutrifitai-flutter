import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/workouts_api.dart';
import '../../models/workout.dart';
import '../../theme/app_colors.dart';
import '../../services/ai_service.dart';
import '../../services/exercise_db_service.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final WorkoutsApi _api = WorkoutsApi();
  List<Workout> _workouts = [];
  bool _isLoading = true;

  int? _selectedDays;
  String? _selectedFormat;
  List<Map<String, dynamic>>? _weekPlan;
  bool _isGenerating = false;

  static const List<Map<String, String>> _formats = [
    {
      'name': 'Фулл бади',
      'key': 'full_body',
      'info': 'Все группы мышц за одну тренировку. Подходит для новичков и тренировок 2-3 раза в неделю.',
    },
    {
      'name': 'Верх / Низ',
      'key': 'upper_lower',
      'info': 'Чередование тренировок верхней и нижней части тела. Хороший баланс нагрузки для 4 дней в неделю.',
    },
    {
      'name': 'Сплит',
      'key': 'split',
      'info': 'Каждая тренировка на отдельную группу мышц (грудь, спина, ноги, плечи, руки). Для опытных, 4-6 дней.',
    },
    {
      'name': 'Push / Pull / Legs',
      'key': 'ppl',
      'info': 'Жимовые движения / Тяговые движения / Ноги. Популярная программа для 3-6 дней в неделю.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadSavedPlan();
  }

  Future<void> _savePlan() async {
    final prefs = await SharedPreferences.getInstance();
    if (_weekPlan != null) {
      prefs.setString('workout_plan', json.encode(_weekPlan));
      if (_selectedDays != null) prefs.setInt('workout_days', _selectedDays!);
      if (_selectedFormat != null) prefs.setString('workout_format', _selectedFormat!);
    } else {
      prefs.remove('workout_plan');
      prefs.remove('workout_days');
      prefs.remove('workout_format');
    }
  }

  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = prefs.getString('workout_plan');
    if (planJson != null) {
      try {
        final List<dynamic> parsed = json.decode(planJson);
        setState(() {
          _weekPlan = parsed.map((d) => Map<String, dynamic>.from(d)).toList();
          for (final day in _weekPlan!) {
            day['exercises'] = (day['exercises'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          _selectedDays = prefs.getInt('workout_days');
          _selectedFormat = prefs.getString('workout_format');
        });
      } catch (e) {
        print('Load plan error: $e');
      }
    }
  }

  List<Workout> get _todayWorkouts {
    final today = DateTime.now();
    return _workouts.where((w) =>
      w.workoutDate.year == today.year &&
      w.workoutDate.month == today.month &&
      w.workoutDate.day == today.day,
    ).toList();
  }

  int get _totalDuration =>
      _todayWorkouts.fold(0, (sum, w) => sum + w.durationMinutes);
  int get _totalCalories =>
      _todayWorkouts.fold(0, (sum, w) => sum + w.caloriesBurned.toInt());

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final workouts = await _api.getWorkouts();
      setState(() {
        _workouts = workouts;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить тренировки')),
        );
      }
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    if (workout.id == null) return;
    final ok = await _api.deleteWorkout(workout.id!);
    if (ok) {
      setState(() => _workouts.remove(workout));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить')),
        );
      }
    }
  }

  String _workoutEmoji(String type) {
    final t = type.toLowerCase();
    if (t.contains('бег')) return '🏃';
    if (t.contains('зал') || t.contains('сила')) return '🏋️';
    if (t.contains('кардио')) return '❤️';
    if (t.contains('йога')) return '🧘';
    if (t.contains('плавание')) return '🏊';
    return '💪';
  }

  Future<void> _generatePlan() async {
    if (_selectedDays == null || _selectedFormat == null) return;
    setState(() {
      _isGenerating = true;
      _weekPlan = null;
    });
    try {
      final formatInfo = _formats.firstWhere((f) => f['key'] == _selectedFormat);
      final aiService = AiService();
      final response = await aiService.getRecommendation(
        prompt: '''Составь план тренировок на неделю.
Формат: ${formatInfo['name']}
Дней в неделю: $_selectedDays
Ответь СТРОГО в JSON формате без markdown, без \`\`\`json\`\`\`, только чистый JSON:
[
  {
    "day": "Понедельник",
    "title": "Грудь и трицепс",
    "exercises": [
      {"name": "Жим лёжа", "nameEn": "Barbell Bench Press", "sets": "4x10", "muscle": "Грудь"},
      {"name": "Разводка гантелей", "nameEn": "Dumbbell Flye", "sets": "3x12", "muscle": "Грудь"}
    ]
  }
]
Каждый день должен содержать 6-8 упражнений для фулл бади и 5-7 для остальных форматов. Дни без тренировок не включай. Для каждого упражнения обязательно укажи поле "nameEn" — каноничное английское название (например: Bench Press, Squat, Deadlift, Pull-Up, Push-Up, Bicep Curl, Lat Pulldown, Overhead Press). Используй стандартные английские названия из бодибилдинга. Только JSON массив, ничего больше.''',
        withPersonalData: true,
      );
      try {
        final String jsonStr = _sanitizeAiJson(response);
        final List<dynamic> parsed = json.decode(jsonStr);
        final plan = parsed.map((day) {
          final exercises = (day['exercises'] as List).map((e) {
            return {
              'name': e['name']?.toString() ?? '',
              'nameEn': e['nameEn']?.toString() ?? '',
              'sets': e['sets']?.toString() ?? '',
              'muscle': e['muscle']?.toString() ?? '',
              'done': false,
            };
          }).toList();
          return {
            'day': day['day']?.toString() ?? '',
            'title': day['title']?.toString() ?? '',
            'exercises': exercises,
          };
        }).toList();
        if (mounted) {
          setState(() {
            _weekPlan = List<Map<String, dynamic>>.from(plan);
            _isGenerating = false;
          });
          _savePlan();
        }
      } catch (parseError) {
        print('JSON parse error: $parseError');
        print('Raw response: $response');
        if (mounted) {
          setState(() => _isGenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI не смог сгенерировать план. Попробуйте ещё раз.')),
          );
        }
      }
    } catch (e) {
      print('AI plan error: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка генерации плана')),
        );
      }
    }
  }

  void _resetPlan() {
    setState(() {
      _weekPlan = null;
      _selectedDays = null;
      _selectedFormat = null;
    });
    _savePlan();
  }

  void _showFormatInfo(Map<String, String> format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          format['name']!,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          format['info']!,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Future<void> _replaceExercise(int dayIndex, int exerciseIndex) async {
    final day = _weekPlan![dayIndex];
    final exercises = day['exercises'] as List;
    final exercise = exercises[exerciseIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 16),
            Text(
              'Ищу альтернативы для\n"${exercise['name']}"...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );

    try {
      final aiService = AiService();
      final response = await aiService.getRecommendation(
        prompt: '''Дай 4 альтернативных упражнения для "${exercise['name']}" (мышца: ${exercise['muscle']}).
Ответь СТРОГО JSON без markdown:
[
  {"name": "Название", "nameEn": "Exercise Name", "sets": "${exercise['sets']}", "muscle": "${exercise['muscle']}"},
  {"name": "Название2", "nameEn": "Exercise Name2", "sets": "${exercise['sets']}", "muscle": "${exercise['muscle']}"}
]
Для каждого упражнения обязательно укажи поле "nameEn" — каноничное английское название (например: Dips, Push-Up, Squat). Только JSON массив.''',
        withPersonalData: false,
      );

      if (mounted) Navigator.pop(context);

      final List<dynamic> alternatives = json.decode(_sanitizeAiJson(response));

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Замена для "${exercise['name']}"',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Мышца: ${exercise['muscle']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ...alternatives.map((alt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz, color: AppColors.secondary, size: 20),
                  ),
                  title: Text(
                    alt['name']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    alt['sets']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  onTap: () {
                    setState(() {
                      final ex = exercises[exerciseIndex] as Map;
                      ex['name'] = alt['name']?.toString() ?? '';
                      ex['nameEn'] = alt['nameEn']?.toString() ?? '';
                      ex['sets'] = alt['sets']?.toString() ?? ex['sets']?.toString() ?? '';
                      ex['muscle'] = alt['muscle']?.toString() ?? ex['muscle']?.toString() ?? '';
                      ex['done'] = false;
                    });
                    _savePlan();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Заменено на "${alt['name']}"')),
                    );
                  },
                )),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Replace exercise error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось найти альтернативы')),
        );
      }
    }
  }

  void _addCustomExercise(int dayIndex) {
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final muscleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Новое упражнение', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Название (напр. Жим лёжа)',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: setsController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Подходы (напр. 4x10)',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: muscleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Мышца (напр. Грудь)',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final sets = setsController.text.trim();
              final muscle = muscleController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                final exercises = _weekPlan![dayIndex]['exercises'] as List;
                exercises.add({
                  'name': name,
                  'sets': sets.isEmpty ? '3x10' : sets,
                  'muscle': muscle.isEmpty ? 'Общее' : muscle,
                  'done': false,
                });
              });
              _savePlan();
              Navigator.pop(ctx);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayWorkouts = _todayWorkouts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировки'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.heroGradient,
          ),
        ),
        child: Column(
          children: [
            _buildSummaryCard(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadWorkouts,
                      child: todayWorkouts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: todayWorkouts.length,
                              itemBuilder: (context, index) =>
                                  _buildWorkoutCard(todayWorkouts[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Активность сегодня',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalDuration',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'минут',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  '$_totalCalories',
                  'ккал сожжено',
                  Icons.local_fire_department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  '${_todayWorkouts.length}',
                  'тренировок',
                  Icons.list,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final emoji = _workoutEmoji(workout.type);
    final time = DateFormat('HH:mm').format(workout.workoutDate);
    return Dismissible(
      key: ValueKey(workout.id ?? workout.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _deleteWorkout(workout);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withOpacity(0.2),
                          AppColors.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.type,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildWorkoutInfo(
                              Icons.access_time,
                              '${workout.durationMinutes} мин',
                            ),
                            const SizedBox(width: 16),
                            _buildWorkoutInfo(
                              Icons.local_fire_department,
                              '${workout.caloriesBurned.toInt()} ккал',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_weekPlan != null) return _buildWeekPlan();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Тренер', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Составлю план тренировок под тебя', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Сколько дней в неделю?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [2, 3, 4, 5, 6].map((days) {
            final selected = _selectedDays == days;
            return GestureDetector(
              onTap: () => setState(() => _selectedDays = days),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? AppColors.secondary : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.secondary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$days',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Формат тренировок', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._formats.map((format) {
          final selected = _selectedFormat == format['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFormat = format['key']),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.secondary.withOpacity(0.15) : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.secondary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.secondary : Colors.transparent,
                      border: Border.all(
                        color: selected ? AppColors.secondary : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      format['name']!,
                      style: TextStyle(
                        color: selected ? AppColors.secondary : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showFormatInfo(format),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cardDarker,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help_outline, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: (_selectedDays != null && _selectedFormat != null && !_isGenerating)
              ? _generatePlan
              : null,
          icon: _isGenerating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome, color: Colors.white),
          label: Text(
            _isGenerating ? 'Генерирую план...' : 'Сгенерировать план',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            disabledBackgroundColor: AppColors.secondary.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekPlan() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Твой план на неделю',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Сбросить план?', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text(
                      'Текущий план будет удалён. Вы сможете выбрать параметры заново.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _resetPlan();
                        },
                        child: const Text('Сбросить', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.textMuted),
              label: const Text('Сбросить', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._weekPlan!.asMap().entries.map((dayEntry) {
          final dayIndex = dayEntry.key;
          final day = dayEntry.value;
          final exercises = day['exercises'] as List;
          final doneCount = exercises.where((e) => e['done'] == true).length;
          final allDone = exercises.isNotEmpty && doneCount == exercises.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: allDone ? AppColors.success.withOpacity(0.5) : AppColors.border,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: dayIndex == 0,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: allDone ? AppColors.success.withOpacity(0.2) : AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: allDone
                        ? const Icon(Icons.check, color: AppColors.success, size: 20)
                        : Text(
                            '${dayIndex + 1}',
                            style: const TextStyle(color: AppColors.secondary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                title: Text(
                  day['day']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${day['title']} • $doneCount/${exercises.length}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                children: [
                  ...exercises.asMap().entries.map((exEntry) {
                    final exIndex = exEntry.key;
                    final exercise = exEntry.value;
                    final isDone = exercise['done'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success.withOpacity(0.08) : AppColors.cardDarker,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDone ? AppColors.success.withOpacity(0.3) : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => exercise['done'] = !isDone);
                              _savePlan();
                            },
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isDone ? AppColors.success : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isDone ? AppColors.success : AppColors.textMuted,
                                  width: 2,
                                ),
                              ),
                              child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _replaceExercise(dayIndex, exIndex),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise['name']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${exercise['sets']} • ${exercise['muscle']}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _showExerciseInfo(exercise),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.play_circle_outline, color: AppColors.primary, size: 14),
                                          const SizedBox(width: 4),
                                          Text('Как делать?',
                                              style: TextStyle(color: AppColors.primary, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _replaceExercise(dayIndex, exIndex),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.swap_horiz, color: AppColors.textMuted, size: 20),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Удалить упражнение?', style: TextStyle(color: AppColors.textPrimary)),
                                  content: Text(
                                    '${exercise['name']}',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        setState(() => exercises.removeAt(exIndex));
                                        _savePlan();
                                      },
                                      child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, color: AppColors.textMuted, size: 18),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => _addCustomExercise(dayIndex),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: AppColors.textMuted, size: 18),
                          SizedBox(width: 6),
                          Text('Добавить упражнение', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _sanitizeAiJson(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'```json', caseSensitive: false), '');
    s = s.replaceAll('```', '');
    s = s.trim();
    final startMatch = s.indexOf(RegExp(r'[\[{]'));
    final end = s.lastIndexOf(']') > s.lastIndexOf('}')
        ? s.lastIndexOf(']')
        : s.lastIndexOf('}');
    if (startMatch >= 0 && end > startMatch) {
      s = s.substring(startMatch, end + 1);
    }
    s = s.replaceAllMapped(RegExp(r',(\s*[}\]])'), (m) => m.group(1)!);
    return s;
  }

  void _showExerciseInfo(Map<String, dynamic> exercise) async {
    final nameEn = exercise['nameEn']?.toString()?.isNotEmpty == true
        ? exercise['nameEn'].toString()
        : exercise['name']?.toString() ?? '';
    final dbEntry = await ExerciseDbService.findByName(nameEn);
    if (!mounted) return;
    final title = exercise['name']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (dbEntry == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('Демонстрация для этого упражнения не найдена в базе.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        return _ExerciseInfoSheet(title: title, dbEntry: dbEntry);
      },
    );
  }
}

class _ExerciseInfoSheet extends StatefulWidget {
  final String title;
  final Map<String, dynamic> dbEntry;
  const _ExerciseInfoSheet({required this.title, required this.dbEntry});
  @override
  State<_ExerciseInfoSheet> createState() => _ExerciseInfoSheetState();
}

class _ExerciseInfoSheetState extends State<_ExerciseInfoSheet> {
  final PageController _pageCtrl = PageController();
  Timer? _frameTimer;
  int _frame = 0;
  int _loops = 0;
  bool _animDone = false;
  static const int _maxLoops = 3;
  late List<String> _images;
  late List<String> _enInstructions;
  List<String>? _ruInstructions;
  bool _translating = true;

  @override
  void initState() {
    super.initState();
    _images = (widget.dbEntry['images'] as List?)?.cast<String>() ?? [];
    _enInstructions =
        (widget.dbEntry['instructions'] as List?)?.cast<String>() ?? [];
    _startFrameAnimation();
    _translate();
  }

  void _startFrameAnimation() {
    if (_images.length < 2) return;
    _frameTimer?.cancel();
    _loops = 0;
    _animDone = false;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted || !_pageCtrl.hasClients) return;
      final next = (_frame + 1) % _images.length;
      if (next == 0) {
        _loops++;
        if (_loops >= _maxLoops) {
          _frameTimer?.cancel();
          if (mounted) setState(() => _animDone = true);
          return;
        }
      }
      setState(() => _frame = next);
      _pageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    });
  }

  Future<void> _translate() async {
    final key = widget.dbEntry['id']?.toString() ??
        widget.dbEntry['name']?.toString() ??
        widget.title;
    final ru = await ExerciseDbService.translateInstructions(
        key, _enInstructions);
    if (!mounted) return;
    setState(() {
      _ruInstructions = ru;
      _translating = false;
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muscles =
        (widget.dbEntry['primaryMuscles'] as List?)?.cast<String>() ?? [];
    final steps = _ruInstructions ?? _enInstructions;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(widget.dbEntry['name']?.toString() ?? '',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            if (_images.isNotEmpty)
              SizedBox(
                height: 240,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _images.length,
                      onPageChanged: (i) => setState(() => _frame = i),
                      itemBuilder: (_, i) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          ExerciseDbService.imageUrl(_images[i]),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.card),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_frame + 1} / ${_images.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (_animDone && _images.length > 1)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _animDone = false);
                            _startFrameAnimation();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.replay,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Повторить',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('Техника выполнения:',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_translating)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  const Text('Перевод...',
                      style: TextStyle(color: AppColors.textMuted)),
                ]),
              )
            else
              ...steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(e.value,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    height: 1.4))),
                      ],
                    ),
                  )),
            if (muscles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                  spacing: 6,
                  children: muscles
                      .map((m) => Chip(
                            label: Text(ExerciseDbService.muscleRu(m),
                                style: const TextStyle(fontSize: 11)),
                            backgroundColor:
                                AppColors.primary.withOpacity(0.15),
                          ))
                      .toList()),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
