import 'package:dio/dio.dart';
import 'api_client.dart';

class RecommendationsApi {
  /// Get all recommendations for the user
  Future<List<Map<String, dynamic>>> getRecommendations({String? type}) async {
    try {
      final url = type != null ? '/recommendations?type=$type' : '/recommendations';
      final response = await ApiClient.dio.get(url);
      
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  /// Get a specific recommendation by ID
  Future<Map<String, dynamic>?> getRecommendationById(String id) async {
    try {
      print('=== RecommendationsApi.getRecommendationById ===');
      print('Recommendation ID: $id');
      
      final response = await ApiClient.dio.get('/recommendations/$id');
      
      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      print('DioException in getRecommendationById: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    }
  }

  /// Create a new recommendation
  Future<bool> createRecommendation(Map<String, dynamic> recommendationData) async {
    try {
      print('=== RecommendationsApi.createRecommendation ===');
      print('Recommendation data: $recommendationData');
      
      final response = await ApiClient.dio.post(
        '/recommendations',
        data: recommendationData,
      );
      
      print('Create recommendation response status: ${response.statusCode}');
      print('Create recommendation response: ${response.data}');
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('DioException in createRecommendation: ${e.message}');
      print('Response: ${e.response?.statusCode} - ${e.response?.data}');
      return false;
    }
  }
}
