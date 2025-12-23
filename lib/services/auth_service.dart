import 'package:dio/dio.dart';

import '../services/storage_service.dart';

class AuthService {
  // Подставьте свой прод/stage URL через --dart-define=API_URL=...
  static const String _baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  final Dio _dio;

  AuthService({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<bool> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = res.data['token'] as String?;
      if (token == null) return false;

      await StorageService.saveToken(token);
      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final payload = {
        'fullName': data['name'] ?? data['fullName'],
        'email': data['email'],
        'password': data['password'],
      };

      final res = await _dio.post('/api/auth/register', data: payload);
      final ok = res.statusCode == 200 || res.statusCode == 201;

      final token = res.data is Map ? res.data['token'] as String? : null;
      if (token != null) {
        await StorageService.saveToken(token);
      }

      return ok;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearToken();
  }
}
