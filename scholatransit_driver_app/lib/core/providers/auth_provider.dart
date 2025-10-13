import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Driver? driver;
  final String? error;
  final int? otpId;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.driver,
    this.error,
    this.otpId,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Driver? driver,
    String? error,
    int? otpId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      driver: driver ?? this.driver,
      error: error,
      otpId: otpId ?? this.otpId,
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

    if (token != null && driverId != null) {
      print('🔐 DEBUG: Loading driver profile...');
      await _loadDriverProfile();
    } else {
      print('🔐 DEBUG: No authentication found - user needs to login');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
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
        state = state.copyWith(isLoading: false, otpId: otpId);
        return true;
      } else {
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
        state = state.copyWith(isLoading: false, otpId: otpId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed: $e');
      return false;
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.profileEndpoint,
      );

      if (response.success && response.data != null) {
        final user = response.data!['user'] as Map<String, dynamic>?;
        if (user == null) {
          throw Exception('Invalid profile response');
        }
        final driver = Driver.fromJson(user);
        await StorageService.saveDriverId(driver.id);
        await StorageService.saveUserProfile(user);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          driver: driver,
          error: null,
        );
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  Future<void> logout() async {
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
    state = const AuthState();
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
        await StorageService.saveAuthToken(data['access'] ?? data['access_token'] ?? '');
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyLoginOtp({
    required String otpCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final otpId = state.otpId;
      if (otpId == null) {
        state = state.copyWith(isLoading: false, error: 'Missing OTP ID. Please login again.');
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
      state = state.copyWith(isLoading: false, error: 'OTP verification failed: $e');
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
