import 'package:dio/dio.dart';
import 'api_client.dart';

class WorkoutsApi {
  /// Get all workouts for the user
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    try {
      final response = await ApiClient.dio.get('/workouts');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Add a new workout
  Future<bool> addWorkout(Map<String, dynamic> workoutData) async {
    try {
      print('=== WorkoutsApi.addWorkout ===');
      print('Workout data: $workoutData');
      
      final response = await ApiClient.dio.post(
        '/workouts',
        data: workoutData,
      );
      
      print('Add workout response status: ${response.statusCode}');
      print('Add workout response: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('DioException in addWorkout: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }

  /// Update an existing workout
  Future<bool> updateWorkout(String workoutId, Map<String, dynamic> workoutData) async {
    try {
      print('=== WorkoutsApi.updateWorkout ===');
      print('Workout ID: $workoutId');
      print('Workout data: $workoutData');
      
      final response = await ApiClient.dio.put(
        '/workouts/$workoutId',
        data: workoutData,
      );
      
      print('Update workout response status: ${response.statusCode}');
      print('Update workout response: ${response.data}');
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('DioException in updateWorkout: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }

  /// Delete a workout
  Future<bool> deleteWorkout(String workoutId) async {
    try {
      print('=== WorkoutsApi.deleteWorkout ===');
      print('Workout ID: $workoutId');
      
      final response = await ApiClient.dio.delete('/workouts/$workoutId');
      
      print('Delete workout response status: ${response.statusCode}');
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('DioException in deleteWorkout: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }
}
