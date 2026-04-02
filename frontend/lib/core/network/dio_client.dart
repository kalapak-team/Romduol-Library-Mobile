import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

class ApiInterceptor extends Interceptor {
  final Dio dio;

  ApiInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] ??= 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final data = response.data;
      String message = 'An error occurred';
      Map<String, dynamic>? errors;

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
        errors = data['errors'] as Map<String, dynamic>?;
      }

      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          error: ApiException.fromStatusCode(
            response.statusCode!,
            message,
            errors,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    } else if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(),
          type: DioExceptionType.connectionError,
        ),
      );
    } else {
      handler.next(err);
    }
  }
}

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.apiBase,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.add(ApiInterceptor(dio));
    return dio;
  }

  static void reset() => _dio = null;
}
