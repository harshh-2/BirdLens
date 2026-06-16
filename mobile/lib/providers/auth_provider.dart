import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'auth_state.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {

  final AuthService _authService =
      AuthService();

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<bool> signup({
    required String username,
    required String email,
    required String password,
  }) async {

    try {

      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final AuthResponse response =
          await _authService.signup(
        username: username,
        email: email,
        password: password,
      );

      await SecureStorageService
          .saveToken(response.token);

      state = state.copyWith(
        isLoading: false,
        user: response.user,
      );

      return true;

    } on DioException catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data["message"] ??
            "Signup failed",
      );

      return false;

    } catch (_) {

      state = state.copyWith(
        isLoading: false,
        error: "Something went wrong",
      );

      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {

    try {

      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final response =
          await _authService.login(
        email: email,
        password: password,
      );

      await SecureStorageService
          .saveToken(response.token);

      final currentUser =
          User.fromJson(
        await _authService
            .getCurrentUser(),
      );

      state = state.copyWith(
        isLoading: false,
        user: currentUser,
      );

      return true;

    } on DioException catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: e.response?.data["message"] ??
            "Login failed",
      );

      return false;

    } catch (_) {

      state = state.copyWith(
        isLoading: false,
        error: "Something went wrong",
      );

      return false;
    }
  }

  Future<bool> checkAuth() async {
  try {
    final token =
        await SecureStorageService
            .getToken();

    if (token == null) {
      state = const AuthState();
      return false;
    }

    final userData =
        await _authService
            .getCurrentUser();

    state = state.copyWith(
      user: User.fromJson(userData),
    );

    return true;

  } catch (_) {
    await SecureStorageService
        .deleteToken();

    state = const AuthState();

    return false;
  }
}
  Future<void> logout() async {

    await SecureStorageService
        .deleteToken();

    state = const AuthState();
  }
}