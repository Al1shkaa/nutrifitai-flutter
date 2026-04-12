import 'package:dio/dio.dart';
import 'storage_service.dart';

class RecommendationService {
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  final Dio _dio;

  RecommendationService({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<List<Map<String, dynamic>>> getRecommendations({String? type}) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final url = type != null 
          ? '/api/recommendations?type=$type'
          : '/api/recommendations';
      
      final res = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } on DioException catch (e) {
      print('Error fetching recommendations: ${e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRecommendationById(String id) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден');
    }

    try {
      final res = await _dio.get(
        '/api/recommendations/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data is Map) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      print('Error fetching recommendation: ${e.message}');
      return null;
    }
  }
}
