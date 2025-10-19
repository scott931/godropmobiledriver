import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parent_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ParentAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Parent? parent;
  final String? error;
  final int? otpId;
  final String? registrationEmail;

  const ParentAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.parent,
    this.error,
    this.otpId,
    this.registrationEmail,
  });

  ParentAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Parent? parent,
    String? error,
    int? otpId,
    String? registrationEmail,
  }) {
    return ParentAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      parent: parent ?? this.parent,
      error: error,
      otpId: otpId ?? this.otpId,
      registrationEmail: registrationEmail ?? this.registrationEmail,
    );
  }
}

class ParentAuthNotifier extends StateNotifier<ParentAuthState> {
  bool _isCheckingAuth = false;

  ParentAuthNotifier() : super(const ParentAuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_isCheckingAuth) {
      print('🔐 DEBUG: Parent auth check already in progress, skipping...');
      return;
    }

    _isCheckingAuth = true;
    print('🔐 DEBUG: Checking parent authentication status...');

    try {
      final token = StorageService.getAuthToken();
      final parentId = StorageService.getInt('parent_id');

      print('🔐 DEBUG: Token exists: ${token != null}');
      print('🔐 DEBUG: Parent ID: $parentId');

      if (token != null && parentId != null) {
        print('🔐 DEBUG: Found existing parent auth, loading profile...');
        await _loadParentProfile();
      } else {
        print('🔐 DEBUG: No parent authentication found - user needs to login');
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔐 DEBUG: Starting parent login for email: $email');

      // Clear any existing tokens before login
      await StorageService.clearAuthTokens();

      final response = await ApiService.post<Map<String, dynamic>>(
        '/auth/parent/login/',
        data: {'email': email, 'password': password, 'source': 'mobile'},
      );

      print('🔐 DEBUG: Parent login response - Success: ${response.success}');
      print('🔐 DEBUG: Parent login response - Error: ${response.error}');

      if (response.success && response.data != null) {
        final data = response.data!;
        print('🔐 DEBUG: Parent login successful, processing response data');

        int? otpId;
        if (data['otp_id'] is int) {
          otpId = data['otp_id'] as int;
          state = state.copyWith(
            isLoading: false,
            otpId: otpId,
            registrationEmail: email,
          );
          print('🔐 DEBUG: OTP required for parent login');
          return true;
        }

        // Handle successful login
        if (data['tokens'] != null && data['parent'] != null) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          final parentData = data['parent'] as Map<String, dynamic>;

          // Save tokens
          await StorageService.saveAuthToken(tokens['access'] as String);
          await StorageService.saveRefreshToken(tokens['refresh'] as String);

          // Save parent data
          final parent = Parent.fromJson(parentData);
          await StorageService.saveUserProfile(parent.toJson());
          await StorageService.setInt('parent_id', parent.id);

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            parent: parent,
            error: null,
          );

          print('🔐 DEBUG: Parent login completed successfully');
          return true;
        }
      }

      // Handle login failure
      final errorMessage = response.error ?? 'Login failed';
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: errorMessage,
      );

      print('🔐 DEBUG: Parent login failed: $errorMessage');
      return false;
    } catch (e) {
      print('🔐 DEBUG: Parent login error: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: 'Login failed: $e',
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.otpId == null) {
      state = state.copyWith(error: 'No OTP session found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        '/auth/verify-otp/',
        data: {'otp_id': state.otpId, 'otp_code': otp},
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        if (data['tokens'] != null && data['parent'] != null) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          final parentData = data['parent'] as Map<String, dynamic>;

          // Save tokens
          await StorageService.saveAuthToken(tokens['access'] as String);
          await StorageService.saveRefreshToken(tokens['refresh'] as String);

          // Save parent data
          final parent = Parent.fromJson(parentData);
          await StorageService.saveUserProfile(parent.toJson());
          await StorageService.setInt('parent_id', parent.id);

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            parent: parent,
            error: null,
            otpId: null,
            registrationEmail: null,
          );

          print('🔐 DEBUG: Parent OTP verification completed successfully');
          return true;
        }
      }

      final errorMessage = response.error ?? 'OTP verification failed';
      state = state.copyWith(isLoading: false, error: errorMessage);

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'OTP verification failed: $e',
      );
      return false;
    }
  }

  Future<void> _loadParentProfile() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '/auth/parent/profile/',
      );

      if (response.success && response.data != null) {
        final parent = Parent.fromJson(response.data!);
        state = state.copyWith(
          isAuthenticated: true,
          parent: parent,
          error: null,
        );
        print('🔐 DEBUG: Parent profile loaded successfully');
      } else {
        print('🔐 DEBUG: Failed to load parent profile: ${response.error}');
        await logout();
      }
    } catch (e) {
      print('🔐 DEBUG: Error loading parent profile: $e');
      await logout();
    }
  }

  Future<void> logout() async {
    try {
      // Call logout endpoint
      await ApiService.post('/auth/logout/');
    } catch (e) {
      print('🔐 DEBUG: Logout API call failed: $e');
    }

    // Clear local storage
    await StorageService.clearAuthTokens();
    await StorageService.clearUserProfile();
    await StorageService.remove('parent_id');

    state = const ParentAuthState();
    print('🔐 DEBUG: Parent logout completed');
  }

  Future<void> refreshParentProfile() async {
    if (!state.isAuthenticated) return;
    await _loadParentProfile();
  }
}

final parentAuthProvider =
    StateNotifierProvider<ParentAuthNotifier, ParentAuthState>((ref) {
      return ParentAuthNotifier();
    });
