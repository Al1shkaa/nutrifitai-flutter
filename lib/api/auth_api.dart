import 'api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthApi {
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await ApiClient.dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data);
  }

  Future<bool> register(Map<String, dynamic> data) async {
    final response = await ApiClient.dio.post('/auth/register', data: data);
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
