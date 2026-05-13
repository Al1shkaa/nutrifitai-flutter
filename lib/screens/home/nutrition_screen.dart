import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meal.dart';
import '../../api/nutrition_api.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMeals();
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
      // Вернуть блюдо в список если удаление не прошло
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Добавить',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
        // Возвращаем false — _deleteMeal сам управляет списком через setState
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Нет записей о питании',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Добавьте свой первый приём пищи',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext rootContext) {
    final nameController = TextEditingController();
    final productController = TextEditingController();
    final gramsController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    String selectedMealType = 'BREAKFAST';
    bool showMacros = false;

    final mealTypeOptions = {
      'BREAKFAST': 'Завтрак',
      'LUNCH': 'Обед',
      'DINNER': 'Ужин',
      'SNACK': 'Перекус',
    };

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        // Объявляем isSubmitting здесь — builder вызывается один раз,
        // поэтому переменная не сбрасывается при ребилде StatefulBuilder.
        bool isSubmitting = false;
        return StatefulBuilder(
        builder: (ctx, setSheetState) {

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Добавить приём пищи',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _dialogTextField(
                    controller: nameController,
                    label: 'Название',
                    hint: 'Завтрак',
                    icon: Icons.restaurant_menu,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMealType,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15),
                        icon: const Icon(Icons.expand_more,
                            color: AppColors.textSecondary),
                        items: mealTypeOptions.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setSheetState(() => selectedMealType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dialogTextField(
                    controller: productController,
                    label: 'Продукт',
                    hint: 'Овсянка',
                    icon: Icons.set_meal,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogTextField(
                          controller: gramsController,
                          label: 'Грамм',
                          hint: '80',
                          icon: Icons.scale,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogTextField(
                          controller: caloriesController,
                          label: 'Ккал/100г',
                          hint: '380',
                          icon: Icons.local_fire_department,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        setSheetState(() => showMacros = !showMacros),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            showMacros
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            showMacros ? 'Скрыть БЖУ' : 'Подробнее (БЖУ)',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showMacros) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _dialogTextField(
                            controller: proteinController,
                            label: 'Белки',
                            hint: '13',
                            icon: Icons.egg,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogTextField(
                            controller: carbsController,
                            label: 'Углев.',
                            hint: '68',
                            icon: Icons.grain,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dialogTextField(
                            controller: fatController,
                            label: 'Жиры',
                            hint: '7',
                            icon: Icons.water_drop,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  StatefulBuilder(
                    builder: (ctx2, setButtonState) => ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final mealName = nameController.text.trim();
                              final productName =
                                  productController.text.trim();
                              final grams = double.tryParse(
                                  gramsController.text.trim());
                              final calories = double.tryParse(
                                  caloriesController.text.trim());

                              if (mealName.isEmpty ||
                                  productName.isEmpty ||
                                  grams == null ||
                                  calories == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Заполните все обязательные поля'),
                                  ),
                                );
                                return;
                              }

                              final protein = double.tryParse(
                                      proteinController.text.trim()) ??
                                  0.0;
                              final carbs = double.tryParse(
                                      carbsController.text.trim()) ??
                                  0.0;
                              final fat = double.tryParse(
                                      fatController.text.trim()) ??
                                  0.0;

                              final newMeal = Meal(
                                name: mealName,
                                mealType: selectedMealType,
                                mealDate: DateTime.now(),
                                items: [
                                  MealItem(
                                    name: productName,
                                    caloriesPer100g: calories,
                                    protein: protein,
                                    carbs: carbs,
                                    fat: fat,
                                    quantity: grams,
                                  ),
                                ],
                              );

                              setSheetState(() => isSubmitting = true);
                              final created = await _api.addMeal(newMeal);
                              setSheetState(() => isSubmitting = false);

                              if (created != null) {
                                setState(() => _meals.add(created));
                                if (mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Добавлено')),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Не удалось добавить'),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'Добавить',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
