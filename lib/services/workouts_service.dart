import 'package:dio/dio.dart';
import 'storage_service.dart';

class WorkoutsService {
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  final Dio _dio;

  WorkoutsService({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.get(
        '/api/workouts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } on DioException catch (e) {
      print('Error fetching workouts: ${e.message}');
      return [];
    }
  }

  Future<bool> addWorkout(Map<String, dynamic> workoutData) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.post(
        '/api/workouts',
        data: workoutData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      print('Error adding workout: ${e.message}');
      return false;
    }
  }

  Future<bool> updateWorkout(String workoutId, Map<String, dynamic> workoutData) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.put(
        '/api/workouts/$workoutId',
        data: workoutData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return res.statusCode == 200;
    } on DioException catch (e) {
      print('Error updating workout: ${e.message}');
      return false;
    }
  }

  Future<bool> deleteWorkout(String workoutId) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.delete(
        '/api/workouts/$workoutId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return res.statusCode == 200;
    } on DioException catch (e) {
      print('Error deleting workout: ${e.message}');
      return false;
    }
  }
}
