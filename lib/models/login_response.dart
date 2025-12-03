class LoginResponse {
  final String token;
  final String refreshToken;

  LoginResponse({required this.token, required this.refreshToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json["token"],
      refreshToken: json["refreshToken"],
    );
  }
}
