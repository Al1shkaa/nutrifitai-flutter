import 'package:dio/dio.dart';
import 'storage_service.dart';

class NutritionService {
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  final Dio _dio;

  NutritionService({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<List<Map<String, dynamic>>> getMeals() async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.get(
        '/api/nutrition/meals',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } on DioException catch (e) {
      print('Error fetching meals: ${e.message}');
      return [];
    }
  }

  Future<bool> addMeal(Map<String, dynamic> mealData) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.post(
        '/api/nutrition/meals',
        data: mealData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      print('Error adding meal: ${e.message}');
      return false;
    }
  }

  Future<bool> deleteMeal(String mealId) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.delete(
        '/api/nutrition/meals/$mealId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return res.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting meal: ${e.message}');
      return false;
    }
  }
}
