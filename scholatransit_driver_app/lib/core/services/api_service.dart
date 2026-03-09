import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static late Dio _dio;
  static final Connectivity _connectivity = Connectivity();
  static void Function(String message)? _onSuspensionDetected;
  static Future<bool>? _refreshInProgress;

  /// Register callback for when API returns suspension/deactivation (401/403).
  /// Used to log out immediately when any API call hits a suspended account.
  static void setSuspensionCallback(void Function(String message)? callback) {
    _onSuspensionDetected = callback;
  }

  /// Attempt to refresh the access token. Returns true if successful.
  static Future<bool> _attemptTokenRefresh() async {
    if (_refreshInProgress != null) {
      return _refreshInProgress!;
    }
    _refreshInProgress = _doTokenRefresh();
    try {
      return await _refreshInProgress!;
    } finally {
      _refreshInProgress = null;
    }
  }

  static Future<bool> _doTokenRefresh() async {
    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final access =
            data['access'] ?? data['access_token'] ?? '';
        if (access.isNotEmpty) {
          await StorageService.saveAuthToken(access);
          return true;
        }
      }
    } catch (_) {}
    return false;
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
    _dio.interceptors.add(_suspensionInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
    _dio.interceptors.add(_errorInterceptor());
  }

  /// Paths that return the current driver's account status. Only these can trigger suspension.
  /// Trips, assignments, vehicles, etc. may contain "inactive" for entities and must NOT
  /// trigger false logout.
  static bool _isProfilePath(String path) {
    return path.contains('/users/me') || path.contains('/drivers/profile');
  }

  /// Checks successful responses (200) for suspended/inactive account indicators.
  /// Only runs on profile-related endpoints to avoid false logouts from trips,
  /// assignments, etc. where "inactive" may refer to entities, not the driver.
  static Interceptor _suspensionInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        final path = response.requestOptions.path;
        final isAuthEndpoint = path.contains('/login/') ||
            path.contains('/register/') ||
            path.contains('/otp/') ||
            path.contains('/password/reset/') ||
            path.contains('/refresh-token/') ||
            path.contains('/logout');
        if (isAuthEndpoint) {
          handler.next(response);
          return;
        }
        if (response.statusCode == 200 &&
            StorageService.getAuthToken() != null &&
            response.data != null &&
            _isProfilePath(path)) {
          final suspensionMsg = _extractSuspensionMessage(response.data);
          if (suspensionMsg != null && _onSuspensionDetected != null) {
            _onSuspensionDetected!(suspensionMsg);
          }
        }
        handler.next(response);
      },
    );
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
          final status = error.response?.statusCode;
          final data = error.response?.data;
          // When response is null, the failure is connection-level (timeout, unreachable, etc.)
          if (error.response == null) {
            print(
              '❌ API Error: no response (${error.type}) ${error.requestOptions.uri}',
            );
            print('📥 Error: ${error.error ?? "connection failed or timeout"}');
          } else {
            print(
              '❌ API Error: $status ${error.requestOptions.uri}',
            );
            print('📥 Error: $data');
          }
        }
        handler.next(error);
      },
    );
  }

  static Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final code = error.response?.statusCode;
        final path = error.requestOptions.path;
        final isAuthEndpoint = path.contains('/login/') ||
            path.contains('/register/') ||
            path.contains('/otp/') ||
            path.contains('/password/reset/') ||
            path.contains('/refresh-token/') ||
            path.contains('/logout');
        final hasToken = StorageService.getAuthToken() != null;

        // If 401 on non-auth endpoints: try token refresh first
        if (!isAuthEndpoint && code == 401 && hasToken) {
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              // Retry failed - pass error through
            }
          }
        }

        // Suspended/inactive account: any 401/403 with suspension message -> logout
        if (!isAuthEndpoint && (code == 401 || code == 403) && hasToken) {
          final data = error.response?.data;
          final suspensionMsg = _extractSuspensionMessage(data);
          if (suspensionMsg != null && _onSuspensionDetected != null) {
            _onSuspensionDetected!(suspensionMsg);
          }
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
    if (data == null) return null;
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
    if (dataMap == null) return null;

    // 1. Explicitly check user/driver status in nested objects (profile, trips, etc.)
    final status = _getStatusFromResponse(dataMap);
    if (status != null) {
      final s = status.toLowerCase();
      if (s == 'suspended') {
        return 'Your account has been suspended. Please contact your administrator.';
      }
      if (s == 'inactive' || s == 'deactivated') {
        return 'Your account has been deactivated. Please contact your administrator.';
      }
    }

    // 2. Check error message content
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
    if (raw == null) {
      raw = dataMap['message']?.toString() ?? dataMap['detail']?.toString();
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

  /// Extracts status from user/driver in response (supports nested profile_data, driver_info).
  static String? _getStatusFromResponse(Map<String, dynamic> data) {
    String? getStatus(Map<String, dynamic>? m) {
      if (m == null) return null;
      final s = m['status']?.toString();
      if (s != null && s.trim().isNotEmpty) return s;
      final isActive = m['is_active'];
      if (isActive is bool && !isActive) return 'inactive';
      return null;
    }
    Map<String, dynamic>? fromDynamic(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;
    // Check data.driver, data.driver_profile, data.user (common profile wrappers)
    final driver = fromDynamic(data['driver']) ?? fromDynamic(data['driver_profile']);
    if (driver != null) {
      final s = getStatus(driver);
      if (s != null) return s;
    }
    final user = fromDynamic(data['user']);
    if (user != null) {
      final s = getStatus(user);
      if (s != null) return s;
      final pd = fromDynamic(user['profile_data']);
      if (pd != null) {
        final ps = getStatus(pd);
        if (ps != null) return ps;
        final di = fromDynamic(pd['driver_info']) ?? fromDynamic(pd['driver']);
        if (di != null) return getStatus(di);
      }
    }
    final nested = fromDynamic(data['data']);
    if (nested != null) return _getStatusFromResponse(nested);
    return getStatus(data);
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
        return 'Connection timeout. The server may be starting up—please try again in a moment.';
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
        return 'Cannot reach server. It may be starting up—please try again in a moment.';
      case DioExceptionType.badCertificate:
        return 'Certificate error. Please check your connection.';
      case DioExceptionType.unknown:
        return 'Connection failed. Please try again in a moment.';
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
