import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../models/registration_request.dart';
import '../models/otp_response.dart';
import '../models/email_completion_request.dart';
import '../models/email_completion_response.dart';
import '../models/password_reset_request.dart';
import '../models/password_reset_response.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Driver? driver;
  final String? error;
  final int? otpId;
  final String? registrationEmail;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.driver,
    this.error,
    this.otpId,
    this.registrationEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Driver? driver,
    String? error,
    int? otpId,
    String? registrationEmail,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      driver: driver ?? this.driver,
      error: error,
      otpId: otpId ?? this.otpId,
      registrationEmail: registrationEmail ?? this.registrationEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('🔐 DEBUG: Checking authentication status...');
    final token = StorageService.getAuthToken();
    final driverId = StorageService.getDriverId();

    print('🔐 DEBUG: Token exists: ${token != null}');
    print('🔐 DEBUG: Driver ID: $driverId');
    print('🔐 DEBUG: Current registration email: ${state.registrationEmail}');

    if (token != null && driverId != null) {
      print('🔐 DEBUG: Found existing auth, loading profile...');
      await _loadDriverProfile();
    } else {
      print('🔐 DEBUG: No authentication found - user needs to login');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔐 DEBUG: Starting login for email: $email');
      print('🔐 DEBUG: Login endpoint: ${AppConfig.loginEndpoint}');

      // Clear any existing tokens before login
      await StorageService.clearAuthTokens();

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
          'source': 'mobile',
          'device_info': {
            'user_agent': 'Flutter (${Platform.operatingSystem})',
            'device_type': 'mobile',
          },
        },
      );

      print('🔐 DEBUG: Login response - Success: ${response.success}');
      print('🔐 DEBUG: Login response - Error: ${response.error}');
      print('🔐 DEBUG: Login response - Data: ${response.data}');

      if (response.success && response.data != null) {
        // For OTP flow, capture otp_id for the verification step and proceed to OTP screen.
        final data = response.data!;
        print('🔐 DEBUG: Login successful, processing response data');

        int? otpId;
        if (data['otp_id'] is int) {
          otpId = data['otp_id'] as int;
          print('🔐 DEBUG: Found otp_id: $otpId');
        } else {
          // Fallback if nested in delivery_methods
          final delivery = data['delivery_methods'];
          if (delivery is Map && delivery['email'] is Map) {
            final emailMethod = delivery['email'] as Map;
            if (emailMethod['otp_id'] is int) {
              otpId = emailMethod['otp_id'] as int;
              print('🔐 DEBUG: Found otp_id in delivery_methods: $otpId');
            }
          }
        }
        state = state.copyWith(
          isLoading: false,
          otpId: otpId,
          registrationEmail: email,
        );
        print(
          '🔐 DEBUG: Login completed successfully, navigating to OTP screen',
        );
        return true;
      } else {
        print('🔐 DEBUG: Login failed - ${response.error}');
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'source': 'mobile',
          'device_info': {
            'user_agent': 'Flutter (${Platform.operatingSystem})',
            'device_type': 'mobile',
          },
        },
      );

      if (response.success && response.data != null) {
        // For OTP flow, capture otp_id for the verification step and proceed to OTP screen.
        final data = response.data!;
        int? otpId;
        if (data['otp_id'] is int) {
          otpId = data['otp_id'] as int;
        } else {
          // Fallback if nested in delivery_methods
          final delivery = data['delivery_methods'];
          if (delivery is Map && delivery['email'] is Map) {
            final emailMethod = delivery['email'] as Map;
            if (emailMethod['otp_id'] is int) {
              otpId = emailMethod['otp_id'] as int;
            }
          }
        }
        state = state.copyWith(
          isLoading: false,
          otpId: otpId,
          registrationEmail: email,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: $e',
      );
      return false;
    }
  }

  Future<bool> registerWithOtp(RegistrationRequest registrationRequest) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.registerOtpEndpoint,
        data: registrationRequest.toJson(),
      );

      if (response.success && response.data != null) {
        final otpResponse = OtpResponse.fromJson(response.data!);

        if (otpResponse.requiresOtp && otpResponse.otpId != null) {
          print(
            '🔐 DEBUG: Setting registration email: ${registrationRequest.email}',
          );
          print('🔐 DEBUG: Setting OTP ID: ${otpResponse.otpId}');
          state = state.copyWith(
            isLoading: false,
            otpId: otpResponse.otpId,
            registrationEmail: registrationRequest.email,
            error: null,
          );
          print(
            '🔐 DEBUG: Registration state updated - email: ${state.registrationEmail}, otpId: ${state.otpId}',
          );
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Registration failed: OTP not sent',
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: $e',
      );
      return false;
    }
  }

  Future<void> loadDriverProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      print(
        '🔐 DEBUG: Loading driver profile from ${AppConfig.profileEndpoint}',
      );
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.profileEndpoint,
      );

      print('🔐 DEBUG: Profile API Response - Success: ${response.success}');
      print('🔐 DEBUG: Profile API Response - Error: ${response.error}');
      print('🔐 DEBUG: Profile API Response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final user = response.data!['user'] as Map<String, dynamic>?;
        if (user == null) {
          print('🔐 DEBUG: ERROR - No user data in profile response');
          throw Exception('Invalid profile response - no user data');
        }

        print('🔐 DEBUG: User data found: $user');
        final driver = Driver.fromJson(user);
        print('🔐 DEBUG: Driver created successfully: ${driver.fullName}');

        await StorageService.saveDriverId(driver.id);
        await StorageService.saveUserProfile(user);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          driver: driver,
          error: null,
        );
        print('🔐 DEBUG: Profile loaded successfully');
      } else {
        print('🔐 DEBUG: ERROR - Profile API failed: ${response.error}');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load profile: ${response.error}',
        );
      }
    } catch (e) {
      print('🔐 DEBUG: ERROR - Exception loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }

  Future<void> logout({bool preserveRegistrationState = false}) async {
    try {
      // Call logout API only if we have a token
      final token = StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.post(AppConfig.logoutEndpoint);
      }
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear stored data
    await StorageService.clearAuthTokens();
    await StorageService.clearUserProfile();
    await StorageService.clearDriverId();
    await StorageService.clearCurrentTrip();

    print('🔐 DEBUG: User logged out, clearing auth state');

    // Preserve registration state if requested (e.g., during auth status checks)
    if (preserveRegistrationState && state.registrationEmail != null) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        driver: null,
        error: null,
        otpId: null,
        // Keep registrationEmail
      );
    } else {
      state = const AuthState();
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.refreshTokenEndpoint,
        data: {'refresh': refreshToken},
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        await StorageService.saveAuthToken(
          data['access'] ?? data['access_token'] ?? '',
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyLoginOtp({required String otpCode}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final otpId = state.otpId;
      if (otpId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Missing OTP ID. Please login again.',
        );
        return false;
      }
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.verifyOtpLoginEndpoint,
        data: {
          'otp_code': otpCode,
          'otp_id': otpId,
          'source': 'mobile',
          'device_info': {
            'user_agent': 'Flutter (${Platform.operatingSystem})',
            'device_type': 'mobile',
          },
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tokens = data['tokens'] as Map<String, dynamic>?;

        if (tokens != null) {
          await StorageService.saveAuthToken(tokens['access'] ?? '');
          await StorageService.saveRefreshToken(tokens['refresh'] ?? '');
        }

        // If user object is present, use it to finalize auth without another API call
        final user = data['user'];
        if (user is Map<String, dynamic>) {
          // Persist basic profile info
          await StorageService.saveUserProfile(user);
          if (user['id'] is int) {
            await StorageService.saveDriverId(user['id'] as int);
          }

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            error: null,
            otpId: null,
          );
          return true;
        }

        // Fallback: if no user in response, try loading profile endpoint
        await _loadDriverProfile();
        state = state.copyWith(otpId: null);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'OTP verification failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'OTP verification failed: $e',
      );
      return false;
    }
  }

  Future<bool> verifyRegisterOtp({required String otpCode}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final otpId = state.otpId;
      if (otpId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Missing OTP ID. Please register again.',
        );
        return false;
      }
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.verifyOtpRegisterEndpoint,
        data: {
          'otp_code': otpCode,
          'otp_id': otpId,
          'source': 'mobile',
          'device_info': {
            'user_agent': 'Flutter (${Platform.operatingSystem})',
            'device_type': 'mobile',
          },
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tokens = data['tokens'] as Map<String, dynamic>?;

        if (tokens != null) {
          await StorageService.saveAuthToken(tokens['access'] ?? '');
          await StorageService.saveRefreshToken(tokens['refresh'] ?? '');
        }

        // If user object is present, use it to finalize auth without another API call
        final user = data['user'];
        if (user is Map<String, dynamic>) {
          // Persist basic profile info
          await StorageService.saveUserProfile(user);
          if (user['id'] is int) {
            await StorageService.saveDriverId(user['id'] as int);
          }

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            error: null,
            otpId: null,
          );
          return true;
        }

        // Fallback: if no user in response, try loading profile endpoint
        await _loadDriverProfile();
        state = state.copyWith(otpId: null);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'OTP verification failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'OTP verification failed: $e',
      );
      return false;
    }
  }

  Future<bool> completeEmailRegistration({required String otpCode}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final email = state.registrationEmail;
      print('🔐 DEBUG: Attempting email completion with email: $email');
      print(
        '🔐 DEBUG: Current auth state - isAuthenticated: ${state.isAuthenticated}, otpId: ${state.otpId}',
      );

      if (email == null) {
        print('🔐 DEBUG: ERROR - Missing registration email in state');
        state = state.copyWith(
          isLoading: false,
          error: 'Missing registration email. Please register again.',
        );
        return false;
      }

      final request = EmailCompletionRequest(email: email, otpCode: otpCode);

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.registerEmailCompleteEndpoint,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final completionResponse = EmailCompletionResponse.fromJson(
          response.data!,
        );

        if (completionResponse.success && completionResponse.tokens != null) {
          // Save tokens
          await StorageService.saveAuthToken(completionResponse.tokens!.access);
          await StorageService.saveRefreshToken(
            completionResponse.tokens!.refresh,
          );

          // Save user data if available
          if (completionResponse.user != null) {
            await StorageService.saveUserProfile(
              completionResponse.user!.toJson(),
            );
            await StorageService.saveDriverId(completionResponse.user!.id);
          }

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            error: null,
            otpId: null,
            registrationEmail: null,
          );
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: completionResponse.message,
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Email registration completion failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email registration completion failed: $e',
      );
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = PasswordResetRequest(email: email);

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.passwordResetEndpoint,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final resetResponse = PasswordResetResponse.fromJson(response.data!);

        if (resetResponse.success) {
          state = state.copyWith(isLoading: false, error: null);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: resetResponse.message,
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Password reset failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password reset failed: $e',
      );
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (state.driver == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.put<Map<String, dynamic>>(
        AppConfig.driverProfileEndpoint,
        data: updates,
      );

      if (response.success && response.data != null) {
        final updatedDriver = Driver.fromJson(response.data!);
        await StorageService.saveUserProfile(updatedDriver.toJson());

        state = state.copyWith(
          isLoading: false,
          driver: updatedDriver,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Profile update failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile update failed: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentDriverProvider = Provider<Driver?>((ref) {
  return ref.watch(authProvider).driver;
});
