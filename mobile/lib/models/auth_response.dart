import 'user.dart';

class AuthResponse {
  final String message;
  final String token;
  final User user;

  const AuthResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthResponse(
      message:
          json['message'] as String,
      token:
          json['token'] as String,
      user: User.fromJson(
        json['user'],
      ),
    );
  }
}