import 'package:dio/dio.dart';
import 'package:birdlens/constants/api_constants.dart';
import 'package:birdlens/services/secure_storage_service.dart';

class DioClient {
  DioClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          options,
          handler,
        ) async {
          final token =
              await SecureStorageService
                  .getToken();

          if (token != null) {
            options.headers[
                'Authorization'] =
                'Bearer $token';
          }

          handler.next(options);
          
        },
    onError: (error, handler) async {
  if (error.response?.statusCode == 401) {
    await SecureStorageService.deleteToken();
  }
  handler.next(error);
}
      ),
    );
    
}
