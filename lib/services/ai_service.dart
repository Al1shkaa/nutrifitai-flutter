import 'package:dio/dio.dart';
import '../api/api_client.dart';
import 'storage_service.dart';

class AiService {
  final Dio _dio = ApiClient.dio;

  Future<String> getRecommendation({String? prompt, bool withPersonalData = false}) async {
    // В зависимости от логики бэкенда, можно отправлять токен всегда,
    // а withPersonalData будет флагом для использования данных профиля на сервере.
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('Токен не найден. Войдите снова.');
    }

    try {
      // ApiClient автоматически добавит токен
      final res = await _dio.post(
        '/ai/recommend',
        data: {
          if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
          'withPersonalData': withPersonalData,
        },
      );

      final data = res.data;
      if (data is Map && data['recommendation'] is String) {
        return data['recommendation'] as String;
      }
      throw Exception('Некорректный ответ сервера');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error'] as String? ?? 'Ошибка запроса')
          : 'Ошибка запроса: ${e.message}';
      throw Exception(msg);
    }
  }
}

