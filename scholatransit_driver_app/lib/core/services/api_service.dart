import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static late Dio _dio;
  static final Connectivity _connectivity = Connectivity();
  static void Function(String message)? _onSuspensionDetected;

  /// Register callback for when API returns suspension/deactivation (401/403).
  /// Used to log out immediately when any API call hits a suspended account.
  static void setSuspensionCallback(void Function(String message)? callback) {
    _onSuspensionDetected = callback;
  }

  static Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  static Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Only add auth token for non-auth endpoints
        final path = options.path;
        final isAuthEndpoint =
            path.contains('/login/') ||
            path.contains('/register/') ||
            path.contains('/password/reset/') ||
            path.contains('/otp/') ||
            path.contains('/refresh-token/');

        if (!isAuthEndpoint) {
          final token = StorageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        // Don't override Content-Type if it's already set (e.g., for FormData)
        // Dio will automatically set multipart/form-data with boundary for FormData
        if (options.data is FormData) {
          // Remove Content-Type header to let Dio set it automatically with boundary
          options.headers.remove('Content-Type');
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // Don't automatically clear tokens on 401 - let the calling code handle it
        // This prevents unwanted logouts when retrying profile loading
        handler.next(error);
      },
    );
  }

  static Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (AppConfig.enableLogging) {
          print('🚀 API Request: ${options.method} ${options.uri}');
          print('📤 Headers: ${options.headers}');
          print('📤 Data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppConfig.enableLogging) {
          print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          print('📥 Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (AppConfig.enableLogging) {
          print(
            '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.uri}',
          );
          print('📥 Error: ${error.response?.data}');
        }
        handler.next(error);
      },
    );
  }

  static Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // If 401/403 with suspension/inactive on non-auth endpoints, invoke callback for immediate logout
        final code = error.response?.statusCode;
        final path = error.requestOptions.path;
        final isAuthEndpoint = path.contains('/login/') ||
            path.contains('/register/') ||
            path.contains('/otp/') ||
            path.contains('/password/reset/') ||
            path.contains('/refresh-token/') ||
            path.contains('/logout');
        // ANY 401/403 on protected endpoints = log out immediately (suspension, token invalid, etc.)
        if (!isAuthEndpoint &&
            (code == 401 || code == 403) &&
            _onSuspensionDetected != null &&
            StorageService.getAuthToken() != null) {
          final msg = _extractSuspensionMessage(error.response?.data) ??
              'Your session has expired or your account is not active. Please sign in again.';
          _onSuspensionDetected!(msg);
        }
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          // Handle timeout errors
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult.contains(ConnectivityResult.none)) {
            error = DioException(
              requestOptions: error.requestOptions,
              error: 'No internet connection',
              type: DioExceptionType.unknown,
            );
          }
        }
        handler.next(error);
      },
    );
  }

  static String? _extractSuspensionMessage(dynamic data) {
    if (data is! Map) return null;
    final dataMap = Map<String, dynamic>.from(data);
    final dataStr = dataMap.toString().toLowerCase();
    if (!dataStr.contains('suspended') &&
        !dataStr.contains('inactive') &&
        !dataStr.contains('deactivated')) {
      return null;
    }
    String? raw;
    final errorData = dataMap['error'];
    if (errorData is Map) {
      final errMap = Map<String, dynamic>.from(errorData);
      final nonFieldErrors = errMap['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        final first = nonFieldErrors.first;
        if (first is String) raw = first;
      }
    }
    if (raw == null && dataMap['non_field_errors'] is List) {
      final list = dataMap['non_field_errors'] as List;
      raw = list.isNotEmpty ? list.first.toString() : null;
    }
    final lower = (raw ?? dataStr).toLowerCase();
    if (lower.contains('inactive') || lower.contains('deactivated')) {
      return 'Your account has been deactivated. Please contact your administrator.';
    }
    if (lower.contains('suspended')) {
      return 'Your account has been suspended. Please contact your administrator.';
    }
    return raw ?? 'Your account is not active. Please contact your administrator.';
  }

  // Generic HTTP methods
  static Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(
        _handleDioError(e),
        e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.success(response.data);
    } on DioException catch (e) {
      return ApiResponse<T>.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: $e');
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        // Handle specific error messages from the API
        if (data is Map) {
          final dataMap = Map<String, dynamic>.from(data);
          // Prefer error.non_field_errors - contains the actual reason (e.g. suspension)
          final errorData = dataMap['error'];
          if (errorData is Map) {
            final errMap = Map<String, dynamic>.from(errorData);
            final nonFieldErrors = errMap['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              final first = nonFieldErrors.first;
              String msg;
              if (first is String) {
                msg = first;
              } else if (first is Map) {
                final fm = Map<String, dynamic>.from(first);
                final s = fm['string'] ?? fm['message'];
                msg = s != null && s.toString().trim().isNotEmpty ? s.toString() : first.toString();
              } else {
                msg = first.toString();
              }
              final lower = msg.toLowerCase();
              if (lower.contains('inactive') || lower.contains('deactivated')) {
                return 'Your account has been deactivated. Please contact your administrator.';
              }
              if (lower.contains('suspended')) {
                return 'Your account has been suspended. Please contact your administrator.';
              }
              return msg;
            }
            if (errMap['message'] != null) return errMap['message'].toString();
          }
          // Also check non_field_errors at root level
          final rootNonField = dataMap['non_field_errors'];
          if (rootNonField is List && rootNonField.isNotEmpty) {
            final first = rootNonField.first;
            final m = first is String ? first : first.toString();
            final ml = m.toString().toLowerCase();
            if (ml.contains('inactive') || ml.contains('deactivated')) return 'Your account has been deactivated. Please contact your administrator.';
            if (ml.contains('suspended')) return 'Your account has been suspended. Please contact your administrator.';
            return m;
          }
          final dataStr = dataMap.toString().toLowerCase();
          if (dataStr.contains('inactive') || dataStr.contains('deactivated')) {
            return 'Your account has been deactivated. Please contact your administrator.';
          }
          if (dataStr.contains('suspended')) {
            return 'Your account has been suspended. Please contact your administrator.';
          }
          if (dataMap['message'] != null) return dataMap['message'].toString();
          if (dataMap['detail'] != null) return dataMap['detail'].toString();
        }

        if (statusCode == 400) {
          return 'Bad request. Please check your input.';
        } else if (statusCode == 401) {
          return 'Invalid credentials. Please check your email and password.';
        } else if (statusCode == 403) {
          return 'Forbidden. You do not have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 422) {
          return 'Validation error. Please check your input.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        } else {
          return 'Request failed with status code $statusCode.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badCertificate:
        return 'Certificate error. Please check your connection.';
      case DioExceptionType.unknown:
        return 'Unknown error occurred. Please try again.';
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, [int? statusCode]) {
    return ApiResponse._(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(String error, [int? statusCode]) {
    return ApiResponse._(success: false, error: error, statusCode: statusCode);
  }
}
