import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../services/storage_service.dart';

class AuthService {
  // Используем общий Dio клиент
  final Dio _dio = ApiClient.dio;

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final payload = {
        'fullName': data['name'] ?? data['fullName'],
        'email': data['email'],
        'password': data['password'],
        'age': data['age'],
      };

      // Путь относительно Constants.baseUrl (который уже включает /api)
      final res = await _dio.post('/auth/register', data: payload);
      final ok = res.statusCode == 200 || res.statusCode == 201;

      final token = res.data is Map ? res.data['token'] as String? : null;
      if (token != null) {
        await StorageService.saveToken(token);

        if (data['name'] != null) {
          await StorageService.saveProfileName(data['name'].toString());
        }
        if (data['age'] != null) {
          await StorageService.saveProfileAge(data['age'].toString());
        }
      }

      return ok;
    } on DioException catch (e) {
      print('Register error: ${e.message}');
      print('Register error response: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Register unexpected error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final payload = {
        'email': email,
        'password': password,
      };

      final res = await _dio.post('/auth/login', data: payload);
      final ok = res.statusCode == 200 || res.statusCode == 201;

      final token = res.data is Map ? res.data['token'] as String? : null;
      if (token != null) {
        await StorageService.saveToken(token);
      }

      return ok;
    } on DioException catch (e) {
      print('Login error: ${e.message}');
      print('Login error response: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Login unexpected error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      // Токен добавляется автоматически через Interceptor в ApiClient
      final res = await _dio.get('/profile');

      if (res.statusCode == 200 && res.data is Map) {
        final profileData = res.data as Map<String, dynamic>;

        // Сохраняем данные профиля локально
        if (profileData['fullName'] != null) {
          await StorageService.saveProfileName(profileData['fullName'].toString());
        }
        if (profileData['weightKg'] != null) {
          await StorageService.saveProfileWeight(profileData['weightKg'].toString());
        }
        if (profileData['heightCm'] != null) {
          await StorageService.saveProfileHeight(profileData['heightCm'].toString());
        }
        if (profileData['age'] != null) {
          await StorageService.saveProfileAge(profileData['age'].toString());
        }
        if (profileData['goal'] != null) {
          await StorageService.saveProfileGoal(profileData['goal'].toString());
        }

        return profileData;
      }
      return null;
    } on DioException catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final payload = <String, dynamic>{};
      if (data['name'] != null) payload['fullName'] = data['name'];
      if (data['weight'] != null) payload['weightKg'] = data['weight'];
      if (data['height'] != null) payload['heightCm'] = data['height'];
      if (data['age'] != null) payload['age'] = data['age'];
      if (data['gender'] != null) payload['gender'] = data['gender'];
      if (data['goal'] != null) payload['goal'] = data['goal'];

      print('Update profile payload: $payload');

      // Токен добавляется автоматически
      final res = await _dio.put(
        '/profile',
        data: payload,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Обновляем локальное хранилище
        if (data['name'] != null) {
          await StorageService.saveProfileName(data['name'].toString());
        }
        if (data['weight'] != null) {
          await StorageService.saveProfileWeight(data['weight'].toString());
        }
        if (data['height'] != null) {
          await StorageService.saveProfileHeight(data['height'].toString());
        }
        if (data['age'] != null) {
          await StorageService.saveProfileAge(data['age'].toString());
        }
        if (data['goal'] != null) {
          await StorageService.saveProfileGoal(data['goal'].toString());
        }
        return true;
      }
      return false;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearToken();
  }
}
