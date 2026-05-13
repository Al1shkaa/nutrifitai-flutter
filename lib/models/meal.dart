class MealItem {
  final int? id;
  final String name;
  final double caloriesPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final double quantity;

  MealItem({
    this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.quantity,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'caloriesPer100g': caloriesPer100g,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'quantity': quantity,
      };
}

class Meal {
  final int? id;
  final int? userId;
  final String name;
  final String mealType;
  final DateTime mealDate;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final List<MealItem> items;

  Meal({
    this.id,
    this.userId,
    required this.name,
    required this.mealType,
    required this.mealDate,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    required this.items,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final items = itemsJson is List
        ? itemsJson
            .map((e) => MealItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MealItem>[];

    return Meal(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      name: json['name'] as String? ?? '',
      mealType: json['mealType'] as String? ?? 'BREAKFAST',
      mealDate: json['mealDate'] != null
          ? DateTime.parse(json['mealDate'] as String)
          : DateTime.now(),
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0.0,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'mealType': mealType,
        'mealDate': mealDate.toIso8601String().split('.')[0],
        'items': items.map((i) => i.toJson()).toList(),
      };
}
