import 'package:dio/dio.dart';
import 'api_client.dart';

class NutritionApi {
  /// Get all meals for the user
  Future<List<Map<String, dynamic>>> getMeals() async {
    try {
      final response = await ApiClient.dio.get('/nutrition/meals');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Add a new meal
  Future<bool> addMeal(Map<String, dynamic> mealData) async {
    try {
      print('=== NutritionApi.addMeal ===');
      print('Meal data: $mealData');
      
      final response = await ApiClient.dio.post(
        '/nutrition/meals',
        data: mealData,
      );
      
      print('Add meal response status: ${response.statusCode}');
      print('Add meal response: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('DioException in addMeal: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }

  /// Delete a meal
  Future<bool> deleteMeal(String mealId) async {
    try {
      print('=== NutritionApi.deleteMeal ===');
      print('Meal ID: $mealId');
      
      final response = await ApiClient.dio.delete('/nutrition/meals/$mealId');
      
      print('Delete meal response status: ${response.statusCode}');
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('DioException in deleteMeal: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }
}
