import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/meal.dart';

class NutritionApi {
  Future<List<Meal>> getMeals() async {
    try {
      final response = await ApiClient.dio.get('/nutrition/meals');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Meal.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  Future<Meal?> addMeal(Meal meal) async {
    try {
      final response = await ApiClient.dio.post(
        '/nutrition/meals',
        data: meal.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Meal.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      print('NutritionApi.addMeal error: ${e.response?.statusCode} ${e.response?.data}');
      return null;
    }
  }

  Future<bool> deleteMeal(int mealId) async {
    try {
      final response = await ApiClient.dio.delete('/nutrition/meals/$mealId');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('NutritionApi.deleteMeal error: ${e.response?.statusCode} ${e.response?.data}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getGoals() async {
    try {
      final response = await ApiClient.dio.get('/nutrition/goals');
      return response.data as Map<String, dynamic>?;
    } on DioException {
      return null;
    }
  }
}
