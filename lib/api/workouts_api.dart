import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/workout.dart';

class WorkoutsApi {
  Future<List<Workout>> getWorkouts() async {
    try {
      final response = await ApiClient.dio.get('/workouts');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Workout.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<Workout?> addWorkout(Workout workout) async {
    try {
      final response = await ApiClient.dio.post(
        '/workouts',
        data: workout.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      print('WorkoutsApi.addWorkout error: ${e.response?.statusCode} ${e.response?.data}');
      return null;
    }
  }

  Future<Workout?> updateWorkout(int id, Workout workout) async {
    try {
      final response = await ApiClient.dio.put(
        '/workouts/$id',
        data: workout.toJson(),
      );
      if (response.statusCode == 200) {
        return Workout.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      print('WorkoutsApi.updateWorkout error: ${e.response?.statusCode} ${e.response?.data}');
      return null;
    }
  }

  Future<bool> deleteWorkout(int id) async {
    try {
      final response = await ApiClient.dio.delete('/workouts/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('WorkoutsApi.deleteWorkout error: ${e.response?.statusCode} ${e.response?.data}');
      return false;
    }
  }
}
