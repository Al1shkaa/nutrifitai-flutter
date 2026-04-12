import 'package:dio/dio.dart';
import 'api_client.dart';

class OnboardingApi {
  /// Get current onboarding status
  /// Returns: { completed: bool, nextStep: String, progress: double }
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await ApiClient.dio.get('/onboarding');
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {};
    } on DioException {
      rethrow;
    }
  }

  /// Update profile field (gender, weight, height, age, goal)
  Future<bool> updateField(String fieldName, dynamic value) async {
    try {
      print('=== OnboardingApi.updateField ===');
      print('Field: $fieldName, Value: $value, ValueType: ${value.runtimeType}');
      
      final response = await ApiClient.dio.post(
        '/onboarding/update',
        data: {
          'field': fieldName,
          'value': value,
        },
      );
      
      print('Update response status: ${response.statusCode}');
      print('Update response data: ${response.data}');
      
      final success = response.statusCode == 200 || response.statusCode == 201;
      print('Update field "$fieldName" success: $success');
      
      return success;
    } on DioException catch (e) {
      print('DioException in updateField ($fieldName): ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      print('Exception type: ${e.type}');
      return false;
    } catch (e) {
      print('Exception in updateField ($fieldName): $e');
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<bool> complete() async {
    try {
      print('=== OnboardingApi.complete ===');
      
      final response = await ApiClient.dio.post('/onboarding/complete');
      
      print('Complete response status: ${response.statusCode}');
      print('Complete response: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('DioException in complete: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }
}
