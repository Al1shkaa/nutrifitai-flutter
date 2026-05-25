import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/meal.dart';
import '../../api/nutrition_api.dart';
import '../../services/ai_service.dart';
import '../../theme/app_colors.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionApi _api = NutritionApi();
  List<Meal> _meals = [];
  bool _isLoading = true;

  // AI meal plan state
  int? _mealsPerDay;
  String? _dietType;
  String? _budget;
  List<String> _allergies = [];
  final _allergyController = TextEditingController();
  List<Map<String, dynamic>>? _mealPlan;
  bool _isGeneratingPlan = false;

  static const List<Map<String, String>> _dietTypes = [
    {'name': 'Обычное', 'key': 'normal', 'info': 'Сбалансированное питание без ограничений. Подходит для большинства людей.'},
    {'name': 'Высокобелковое', 'key': 'high_protein', 'info': 'Упор на белок (30-40% калорий). Идеально для набора мышечной массы и восстановления.'},
    {'name': 'Низкоуглеводное', 'key': 'low_carb', 'info': 'Ограничение углеводов до 20-30%. Помогает при похудении и контроле сахара.'},
    {'name': 'Вегетарианское', 'key': 'vegetarian', 'info': 'Без мяса и рыбы. Белок из яиц, молочных продуктов, бобовых и тофу.'},
  ];

  static const List<Map<String, String>> _budgets = [
    {'name': 'Эконом', 'key': 'economy'},
    {'name': 'Средний', 'key': 'medium'},
    {'name': 'Без ограничений', 'key': 'unlimited'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMeals();
    _loadSavedMealPlan();
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await _api.getMeals();
      setState(() => _meals = meals);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось загрузить блюда')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    if (_mealPlan != null) {
      prefs.setString('meal_plan', json.encode(_mealPlan));
      if (_mealsPerDay != null) prefs.setInt('meals_per_day', _mealsPerDay!);
      if (_dietType != null) prefs.setString('diet_type', _dietType!);
      if (_budget != null) prefs.setString('meal_budget', _budget!);
      prefs.setStringList('allergies', _allergies);
    } else {
      prefs.remove('meal_plan');
      prefs.remove('meals_per_day');
      prefs.remove('diet_type');
      prefs.remove('meal_budget');
    }
  }

  Future<void> _loadSavedMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planJson = prefs.getString('meal_plan');
    if (planJson != null) {
      try {
        final List<dynamic> parsed = json.decode(planJson);
        setState(() {
          _mealPlan = parsed.map((d) => Map<String, dynamic>.from(d as Map)).toList();
          for (final day in _mealPlan!) {
            day['meals'] = (day['meals'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          _mealsPerDay = prefs.getInt('meals_per_day');
          _dietType = prefs.getString('diet_type');
          _budget = prefs.getString('meal_budget');
          _allergies = prefs.getStringList('allergies') ?? [];
        });
      } catch (e) {
        debugPrint('Load meal plan error: $e');
      }
    } else {
      _allergies = prefs.getStringList('allergies') ?? [];
    }
  }

  Future<void> _generateMealPlan() async {
    if (_mealsPerDay == null || _dietType == null || _budget == null) return;
    setState(() => _isGeneratingPlan = true);
    try {
      final dietInfo = _dietTypes.firstWhere((d) => d['key'] == _dietType);
      final budgetInfo = _budgets.firstWhere((b) => b['key'] == _budget);
      final allergyStr = _allergies.isNotEmpty
          ? '\nИсключи полностью эти продукты (аллергия/не нравится): ${_allergies.join(", ")}.'
          : '';

      final aiService = AiService();
      final response = await aiService.getRecommendation(
        prompt: '''Составь план питания на неделю.
Тип: ${dietInfo['name']}
Приёмов пищи в день: $_mealsPerDay
Бюджет: ${budgetInfo['name']}$allergyStr
Ответь СТРОГО JSON без markdown:
[
  {
    "day": "Понедельник",
    "meals": [
      {"type": "Завтрак", "name": "Овсянка с бананом", "calories": 350, "protein": 12, "carbs": 55, "fat": 8, "ingredients": ["овсянка 80г", "банан 1шт"]},
      {"type": "Обед", "name": "Курица с рисом", "calories": 550, "protein": 45, "carbs": 40, "fat": 12, "ingredients": ["курица 200г", "рис 150г"]}
    ]
  }
]
Каждый приём должен содержать name, calories, protein, carbs, fat, ingredients. Только JSON.''',
        withPersonalData: true,
      );

      try {
        String jsonStr = response.trim();
        if (!jsonStr.startsWith('[')) {
          final start = jsonStr.indexOf('[');
          final end = jsonStr.lastIndexOf(']');
          if (start != -1 && end != -1) jsonStr = jsonStr.substring(start, end + 1);
        }
        final List<dynamic> parsed = json.decode(jsonStr);
        final plan = parsed.map((day) {
          final meals = (day['meals'] as List).map((m) {
            return {
              'type': m['type']?.toString() ?? '',
              'name': m['name']?.toString() ?? '',
              'calories': (m['calories'] as num?)?.toInt() ?? 0,
              'protein': (m['protein'] as num?)?.toInt() ?? 0,
              'carbs': (m['carbs'] as num?)?.toInt() ?? 0,
              'fat': (m['fat'] as num?)?.toInt() ?? 0,
              'ingredients': (m['ingredients'] as List?)?.map((i) => i.toString()).toList() ?? [],
              'done': false,
            };
          }).toList();
          return {
            'day': day['day']?.toString() ?? '',
            'meals': meals,
          };
        }).toList();
        if (mounted) {
          setState(() {
            _mealPlan = List<Map<String, dynamic>>.from(plan);
            _isGeneratingPlan = false;
          });
          _saveMealPlan();
        }
      } catch (parseError) {
        debugPrint('Meal plan JSON parse error: $parseError');
        if (mounted) {
          setState(() => _isGeneratingPlan = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось сгенерировать план. Попробуйте ещё раз.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Meal plan error: $e');
      if (mounted) {
        setState(() => _isGeneratingPlan = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка генерации плана питания')),
        );
      }
    }
  }

  Future<void> _resetMealPlan() async {
    if (_mealPlan != null) {
      for (final day in _mealPlan!) {
        final meals = day['meals'] as List? ?? [];
        for (final m in meals) {
          if ((m as Map)['done'] == true) {
            final name = m['name']?.toString() ?? '';
            final match = _meals.where((meal) => meal.name == name).firstOrNull;
            if (match != null) await _api.deleteMeal(match.id!);
          }
        }
      }
    }
    setState(() {
      _mealPlan = null;
      _mealsPerDay = null;
      _dietType = null;
      _budget = null;
    });
    await _saveMealPlan();
    await _loadMeals();
  }

  void _showDietInfo(Map<String, String> diet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(diet['name']!, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(diet['info']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
      ),
    );
  }

  Future<void> _replaceMeal(int dayIndex, int mealIndex) async {
    final day = _mealPlan![dayIndex];
    final meals = day['meals'] as List;
    final meal = meals[mealIndex] as Map;

    final allergyStr = _allergies.isNotEmpty ? ' Исключи: ${_allergies.join(", ")}.' : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Ищу альтернативы для\n"${meal['name']}"...', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );

    try {
      final aiService = AiService();
      final response = await aiService.getRecommendation(
        prompt: 'Дай 4 альтернативных блюда для "${meal['name']}" (${meal['type']}, ~${meal['calories']} ккал).$allergyStr\nОтветь JSON:\n[{"name":"Блюдо","calories":350,"protein":15,"carbs":40,"fat":10,"ingredients":["ингр1","ингр2"]}]\nТолько JSON.',
        withPersonalData: false,
      );

      if (mounted) Navigator.pop(context);

      String jsonStr = response.trim();
      if (!jsonStr.startsWith('[')) {
        final start = jsonStr.indexOf('[');
        final end = jsonStr.lastIndexOf(']');
        if (start != -1 && end != -1) jsonStr = jsonStr.substring(start, end + 1);
      }
      final List<dynamic> alternatives = json.decode(jsonStr);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Замена для "${meal['name']}"', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${meal['type']} • ~${meal['calories']} ккал', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                ...alternatives.map((alt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 20),
                  ),
                  title: Text(alt['name']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${alt['calories'] ?? 0} ккал • ${alt['protein'] ?? 0}г белка', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      final m = meals[mealIndex] as Map;
                      m['name'] = alt['name']?.toString() ?? '';
                      m['calories'] = (alt['calories'] as num?)?.toInt() ?? 0;
                      m['protein'] = (alt['protein'] as num?)?.toInt() ?? 0;
                      m['carbs'] = (alt['carbs'] as num?)?.toInt() ?? 0;
                      m['fat'] = (alt['fat'] as num?)?.toInt() ?? 0;
                      m['ingredients'] = (alt['ingredients'] as List?)?.map((i) => i.toString()).toList() ?? [];
                      m['done'] = false;
                    });
                    _saveMealPlan();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заменено на "${alt['name']}"')));
                  },
                )),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось найти альтернативы')));
    }
  }

  Future<void> _markMealEaten(int dayIndex, int mealIndex) async {
    final day = _mealPlan![dayIndex];
    final meals = day['meals'] as List;
    final meal = meals[mealIndex] as Map;

    String mealType = 'SNACK';
    final typeStr = meal['type']?.toString().toLowerCase() ?? '';
    if (typeStr.contains('завтрак')) {
      mealType = 'BREAKFAST';
    } else if (typeStr.contains('обед')) {
      mealType = 'LUNCH';
    } else if (typeStr.contains('ужин')) {
      mealType = 'DINNER';
    }

    final calories = (meal['calories'] as num?)?.toDouble() ?? 0;
    final protein = (meal['protein'] as num?)?.toDouble() ?? 0;
    final carbs = (meal['carbs'] as num?)?.toDouble() ?? 0;
    final fat = (meal['fat'] as num?)?.toDouble() ?? 0;

    // quantity=100, caloriesPer100g=calories → server computes totalCalories = calories
    final newMeal = Meal(
      name: meal['name']?.toString() ?? 'Приём пищи',
      mealType: mealType,
      mealDate: DateTime.now(),
      items: [
        MealItem(
          name: meal['name']?.toString() ?? '',
          caloriesPer100g: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          quantity: 100,
        ),
      ],
    );

    final created = await _api.addMeal(newMeal);
    if (created != null) {
      setState(() {
        meal['done'] = true;
        _meals.add(created);
      });
      _saveMealPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Добавлено: "${meal['name']}"')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить в дневник')),
        );
      }
    }
  }

  List<Meal> get _todayMeals {
    final today = DateTime.now();
    return _meals.where((m) =>
        m.mealDate.year == today.year &&
        m.mealDate.month == today.month &&
        m.mealDate.day == today.day,
    ).toList();
  }

  int get _totalCalories =>
      _todayMeals.fold(0, (sum, m) => sum + m.totalCalories.toInt());

  double get _totalProtein =>
      _todayMeals.fold(0.0, (sum, m) => sum + m.totalProtein);

  double get _totalCarbs =>
      _todayMeals.fold(0.0, (sum, m) => sum + m.totalCarbs);

  double get _totalFat =>
      _todayMeals.fold(0.0, (sum, m) => sum + m.totalFat);

  String _mealTypeEmoji(String mealType) {
    switch (mealType) {
      case 'BREAKFAST': return '🍳';
      case 'LUNCH':     return '🍽️';
      case 'DINNER':    return '🍲';
      case 'SNACK':     return '🍪';
      default:          return '🍴';
    }
  }

  Future<void> _deleteMeal(Meal meal) async {
    if (meal.id == null) return;
    final success = await _api.deleteMeal(meal.id!);
    if (success) {
      setState(() => _meals.remove(meal));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено')),
        );
      }
    } else {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayMeals = _todayMeals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дневник питания'),
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
                  : _mealPlan != null
                      ? _buildMealPlanView()
                      : todayMeals.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadMeals,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: todayMeals.length,
                                itemBuilder: (context, index) =>
                                    _buildMealCard(todayMeals[index]),
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
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
                    'Калории сегодня',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_totalCalories',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'ккал',
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
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Белки',
                    '${_totalProtein.toStringAsFixed(1)}г', Icons.egg),
                _buildStatItem('Жиры',
                    '${_totalFat.toStringAsFixed(1)}г', Icons.water_drop),
                _buildStatItem('Углеводы',
                    '${_totalCarbs.toStringAsFixed(1)}г', Icons.grain),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    final emoji = _mealTypeEmoji(meal.mealType);
    final timeStr = DateFormat('HH:mm').format(meal.mealDate);

    return Dismissible(
      key: Key('meal_${meal.id ?? meal.name}_${meal.mealDate.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _deleteMeal(meal);
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
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${meal.totalCalories.toInt()}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildEmptyState() {
    if (_mealPlan != null) return _buildMealPlanView();

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
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Нутрициолог', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Составлю персональный план питания на неделю', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Приёмов пищи в день', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [3, 4, 5, 6].map((count) {
            final selected = _mealsPerDay == count;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _mealsPerDay = count),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: selected ? LinearGradient(colors: AppColors.primaryGradient) : null,
                    color: selected ? null : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$count', style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                      Text('раз', style: TextStyle(color: selected ? Colors.white70 : AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        const Text('Тип питания', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._dietTypes.map((diet) {
          final selected = _dietType == diet['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => setState(() => _dietType = diet['key']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.secondary.withOpacity(0.1)])
                      : null,
                  color: selected ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        diet['name']!,
                        style: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDietInfo(diet),
                      child: const Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),

        const Text('Бюджет', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: _budgets.map((budget) {
            final selected = _budget == budget['key'];
            return GestureDetector(
              onTap: () => setState(() => _budget = budget['key']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected ? LinearGradient(colors: AppColors.primaryGradient) : null,
                  color: selected ? null : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  budget['name']!,
                  style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        const Text('Исключения и аллергии', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Необязательно', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _allergyController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Глютен, орехи, молоко...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (val) {
                  final trimmed = val.trim();
                  if (trimmed.isNotEmpty && !_allergies.contains(trimmed)) {
                    setState(() => _allergies.add(trimmed));
                    _allergyController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                final trimmed = _allergyController.text.trim();
                if (trimmed.isNotEmpty && !_allergies.contains(trimmed)) {
                  setState(() => _allergies.add(trimmed));
                  _allergyController.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add, color: AppColors.primary),
              ),
            ),
          ],
        ),
        if (_allergies.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _allergies.map((a) => Chip(
              label: Text(a, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              backgroundColor: AppColors.card,
              deleteIconColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.border),
              onDeleted: () => setState(() => _allergies.remove(a)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_mealsPerDay != null && _dietType != null && _budget != null && !_isGeneratingPlan)
                ? _generateMealPlan
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.card,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isGeneratingPlan
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 12),
                      Text('Генерирую план...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Составить план питания', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMealPlanView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('План питания на неделю', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('Нажми "Съел" — блюдо попадёт в дневник', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
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
                    content: const Text('Текущий план питания будет удалён.', style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); _resetMealPlan(); },
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
        const SizedBox(height: 16),

        ...(_mealPlan ?? []).asMap().entries.map((dayEntry) {
          final dayIndex = dayEntry.key;
          final day = dayEntry.value;
          final meals = day['meals'] as List;
          final doneCount = meals.where((m) => (m as Map)['done'] == true).length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: doneCount == meals.length && meals.isNotEmpty
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    doneCount == meals.length && meals.isNotEmpty ? Icons.check_circle : Icons.calendar_today,
                    color: doneCount == meals.length && meals.isNotEmpty ? AppColors.primary : AppColors.textMuted,
                    size: 18,
                  ),
                ),
                title: Text(day['day']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                subtitle: Text('$doneCount/${meals.length} приёмов', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                children: [
                  ...meals.asMap().entries.map((mealEntry) {
                  final mealIndex = mealEntry.key;
                  final meal = mealEntry.value as Map;
                  final isDone = meal['done'] == true;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDone ? AppColors.primary.withOpacity(0.3) : AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(meal['type']?.toString() ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                                const Spacer(),
                                Text('${meal['calories'] ?? 0} ккал', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('Б${meal['protein'] ?? 0} У${meal['carbs'] ?? 0} Ж${meal['fat'] ?? 0}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              meal['name']?.toString() ?? '',
                              style: TextStyle(
                                color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if ((meal['ingredients'] as List?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                (meal['ingredients'] as List).join(' • '),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: isDone ? null : () => _markMealEaten(dayIndex, mealIndex),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDone ? AppColors.primary.withOpacity(0.1) : AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(isDone ? Icons.check : Icons.restaurant, color: isDone ? AppColors.primary : Colors.white, size: 16),
                                          const SizedBox(width: 6),
                                          Text(isDone ? 'Съедено' : 'Съел', style: TextStyle(color: isDone ? AppColors.primary : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isDone) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _replaceMeal(dayIndex, mealIndex),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                    child: const Icon(Icons.swap_horiz, color: AppColors.textSecondary, size: 18),
                                  ),
                                ),
                                ],
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.surface,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Удалить блюдо?', style: TextStyle(color: AppColors.textPrimary)),
                                        content: Text('"${meal['name']}" будет удалено из плана.', style: const TextStyle(color: AppColors.textSecondary)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              if (meal['done'] == true) {
                                                final name = meal['name']?.toString() ?? '';
                                                final match = _meals.where((m) => m.name == name).firstOrNull;
                                                if (match != null) await _api.deleteMeal(match.id!);
                                                await _loadMeals();
                                              }
                                              setState(() => meals.removeAt(mealIndex));
                                              _saveMealPlan();
                                            },
                                            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                    child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: GestureDetector(
                      onTap: () => _addManualMeal(dayIndex: dayIndex),
                      child: Container(
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
                            Text('Добавить блюдо', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  void _addManualMeal({int? dayIndex}) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String mealType = 'BREAKFAST';
    final types = {'BREAKFAST': 'Завтрак', 'LUNCH': 'Обед', 'DINNER': 'Ужин', 'SNACK': 'Перекус'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) => Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Добавить приём пищи', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Название блюда', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: types.entries.map((e) {
                      final sel = mealType == e.key;
                      return GestureDetector(
                        onTap: () => setSheetState(() => mealType = e.key),
                        child: Chip(label: Text(e.value, style: TextStyle(color: sel ? Colors.white : AppColors.textPrimary, fontSize: 13)), backgroundColor: sel ? AppColors.primary : AppColors.card, side: BorderSide(color: sel ? AppColors.primary : AppColors.border)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Ккал', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2))))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: proteinCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Белки', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2))))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: carbsCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Углеводы', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2))))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(hintText: 'Жиры', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2))))),
                  ]),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final cal = double.tryParse(calCtrl.text.trim()) ?? 0;
                      if (name.isEmpty) return;
                      final protein = double.tryParse(proteinCtrl.text.trim()) ?? 0;
                      final carbs = double.tryParse(carbsCtrl.text.trim()) ?? 0;
                      final fat = double.tryParse(fatCtrl.text.trim()) ?? 0;
                      final newMeal = Meal(name: name, mealType: mealType, mealDate: DateTime.now(), items: [MealItem(name: name, caloriesPer100g: cal, protein: protein, carbs: carbs, fat: fat, quantity: 100)]);
                      final created = await _api.addMeal(newMeal);
                      if (created != null && mounted) {
                        setState(() {
                          _meals.add(created);
                          if (dayIndex != null && _mealPlan != null) {
                            final dayMeals = _mealPlan![dayIndex]['meals'] as List;
                            dayMeals.add({
                              'type': types[mealType] ?? 'Перекус',
                              'name': name,
                              'calories': cal.toInt(),
                              'protein': protein.toInt(),
                              'carbs': carbs.toInt(),
                              'fat': fat.toInt(),
                              'ingredients': [],
                              'done': true,
                            });
                          }
                        });
                        if (dayIndex != null) _saveMealPlan();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Добавлено: "$name"')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Добавить', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
