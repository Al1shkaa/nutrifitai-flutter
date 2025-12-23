import 'package:dio/dio.dart';

import 'storage_service.dart';

class AiService {
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  final Dio _dio;

  AiService({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<String> getRecommendation({String? prompt}) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден. Войдите снова.');
    }

    try {
      final res = await _dio.post(
        '/api/ai/recommend',
        data: prompt == null || prompt.isEmpty ? null : {'prompt': prompt},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = res.data;
      if (data is Map && data['recommendation'] is String) {
        return data['recommendation'] as String;
      }
      throw Exception('Некорректный ответ сервера');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error'] as String? ?? 'Ошибка запроса')
          : 'Ошибка запроса';
      throw Exception(msg);
    }
  }
}

