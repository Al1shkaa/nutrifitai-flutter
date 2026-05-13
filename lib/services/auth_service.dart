import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../services/storage_service.dart';

class VerificationRequiredException implements Exception {
  final String email;
  VerificationRequiredException(this.email);
  @override
  String toString() => 'Email not verified: $email';
}

class AuthService {
  final Dio _dio = ApiClient.dio;

  Future<bool> register(String email, String password) async {
    try {
      await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      return true;
    } on DioException catch (e) {
      print('Register error: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Register unexpected error: $e');
      return false;
    }
  }

  Future<bool> verify(String email, String code) async {
    try {
      final res = await _dio.post('/auth/verify', data: {
        'email': email,
        'code': code,
      });
      final token = res.data is Map ? res.data['token'] as String? : null;
      if (token != null) {
        await StorageService.saveToken(token);
      }
      return true;
    } on DioException catch (e) {
      print('Verify error: ${e.response?.data}');
      return false;
    } catch (e) {
      print('Verify unexpected error: $e');
      return false;
    }
  }

  Future<bool> resendCode(String email) async {
    try {
      await _dio.post('/auth/resend-code', data: {'email': email});
      return true;
    } on DioException catch (e) {
      print('ResendCode error: ${e.response?.data}');
      return false;
    } catch (e) {
      print('ResendCode unexpected error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data is Map ? res.data['token'] as String? : null;
      if (token != null) {
        await StorageService.saveToken(token);
      }
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['error'] ?? '')
          : '';
      if (e.response?.statusCode == 400 &&
          message.toString().toLowerCase().contains('not verified')) {
        throw VerificationRequiredException(email);
      }
      print('Login error: ${e.response?.data}');
      return false;
    } catch (e) {
      rethrow;
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
