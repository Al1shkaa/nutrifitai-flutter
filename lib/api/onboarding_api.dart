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

  /// Update profile field via PATCH /api/profile
  Future<bool> updateField(String fieldName, dynamic value) async {
    try {
      print('=== OnboardingApi.updateField ===');
      print('Field: $fieldName, Value: $value, ValueType: ${value.runtimeType}');

      String profileField;
      switch (fieldName) {
        case 'fullName':
          profileField = 'fullName';
          break;
        case 'gender':
          profileField = 'gender';
          break;
        case 'weight':
          profileField = 'weightKg';
          break;
        case 'height':
          profileField = 'heightCm';
          break;
        case 'age':
          profileField = 'age';
          break;
        case 'goal':
          profileField = 'goal';
          break;
        default:
          profileField = fieldName;
      }

      final response = await ApiClient.dio.patch(
        '/profile',
        data: {profileField: value},
      );

      print('PATCH /profile response: ${response.statusCode} ${response.data}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('PATCH /profile error: ${e.response?.statusCode} ${e.response?.data}');
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
