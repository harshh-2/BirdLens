import 'package:dio/dio.dart';
import 'package:birdlens/services/dio_client.dart';
import 'package:birdlens/models/auth_response.dart';

class AuthService {

  Future<AuthResponse> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response =
        await DioClient.dio.post(
      '/auth/signup',
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(
      response.data,
    );
  }
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response =
        await DioClient.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(
      response.data,
    );
  }
  Future<Map<String, dynamic>>
      getCurrentUser() async {
    final response =
        await DioClient.dio.get(
      '/auth/me',
    );
    return response.data;
  }
}