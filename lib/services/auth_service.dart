import '../services/storage_service.dart';

class AuthService {

  // ВРЕМЕННЫЙ ЛОГИН (пока нет backend)
  Future<bool> login(String email, String password) async {
    // фейковая задержка, как будто запрос
    await Future.delayed(const Duration(milliseconds: 400));

    // сохраняем фейковый токен
    await StorageService.saveToken("fake-test-token");

    return true;
  }

  // ВРЕМЕННАЯ РЕГИСТРАЦИЯ
  Future<bool> register(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  Future<void> logout() async {
    await StorageService.clearToken();
  }
}
