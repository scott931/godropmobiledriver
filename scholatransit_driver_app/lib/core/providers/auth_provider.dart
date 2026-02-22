import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../models/user_role.dart';
import '../models/registration_request.dart';
import '../models/otp_response.dart';
import '../models/email_completion_request.dart';
import '../models/email_completion_response.dart';
import '../models/password_reset_request.dart';
import '../models/password_reset_response.dart';
import '../models/password_reset_confirm_request.dart';
import '../models/password_reset_confirm_response.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Driver? driver;
  /// Raw profile data from API response body (used to display all details from backend)
  final Map<String, dynamic>? profileRawData;
  final String? error;
  final int? otpId;
  final String? registrationEmail;
  /// True when user must change password before accessing app (e.g. new user with temp password).
  /// Null when backend does not send this flag (use flow-based fallback).
  final bool? mustChangePassword;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.driver,
    this.profileRawData,
    this.error,
    this.otpId,
    this.registrationEmail,
    this.mustChangePassword,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Driver? driver,
    Map<String, dynamic>? profileRawData,
    String? error,
    int? otpId,
    String? registrationEmail,
    bool? mustChangePassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      driver: driver ?? this.driver,
      profileRawData: profileRawData ?? this.profileRawData,
      error: error,
      otpId: otpId ?? this.otpId,
      registrationEmail: registrationEmail ?? this.registrationEmail,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

/// Returns true if the user_type is allowed to log in to the driver app (drivers only).
/// Admin, parent, and other non-driver roles are blocked. Unknown/null user_type is blocked
/// to prevent admin access when the backend omits user_type.
bool _isAllowedUserType(String? userType) {
  if (userType == null || userType.toString().trim().isEmpty) return false;
  final role = UserRole.fromString(userType);
  return role == UserRole.driver;
}

/// Returns true if the driver account is active (not suspended or deactivated).
/// Admin can change status via PATCH /api/v1/users/admin/drivers/:id/:
/// - status: 'active' -> allowed
/// - status: 'suspended' -> blocked (temporary)
/// - status: 'inactive' -> blocked (deactivated)
/// Only block when we have explicit suspension/deactivation - assume active when status is missing or unrecognized.
bool _isDriverActive(String? status) {
  if (status == null || status.toString().trim().isEmpty) return true;
  final s = status.toString().toLowerCase();
  if (s == 'suspended' || s == 'inactive') return false;
  return true; // active, on_leave, pending, or unknown -> allow
}

/// Message shown when a non-driver (admin, parent, etc.) tries to access the driver app.
const String _kNonDriverBlockedMessage =
    'Only drivers can access the application. Contact your admin for further assistance.';

// Single canonical message - used everywhere for consistency
const String _kSuspendedMessage =
    'Your account has been suspended. Please contact your administrator.';
const String _kDeactivatedMessage =
    'Your account has been deactivated. Please contact your administrator.';

String _getDriverStatusBlockedMessage(String? status) {
  if (status == null) return 'Your account is not active. Please contact your administrator.';
  final s = status.toString().toLowerCase();
  if (s == 'suspended') return _kSuspendedMessage;
  if (s == 'inactive') return _kDeactivatedMessage;
  return 'Your account is not active. Please contact your administrator.';
}

/// Normalize any error - if it mentions suspended/inactive, return our canonical message.
String _normalizeApiError(String? error, {String fallback = 'An error occurred'}) {
  if (error == null || error.isEmpty) return fallback;
  final lower = error.toLowerCase();
  if (lower.contains('inactive') || lower.contains('deactivated')) return _kDeactivatedMessage;
  if (lower.contains('suspended')) return _kSuspendedMessage;
  return error;
}

/// Extract error from API body. Returns raw message; caller should use _normalizeApiError.
String? _extractErrorFromResponse(Map<String, dynamic> data) {
  try {
    final err = data['error'];
    if (err != null && err is Map) {
      final errMap = Map<String, dynamic>.from(err);
      final list = errMap['non_field_errors'];
      if (list is List && list.isNotEmpty) {
        final first = list.first;
        if (first is String && first.trim().isNotEmpty) return first;
        if (first is Map) {
          final fm = Map<String, dynamic>.from(first);
          final s = fm['string'] ?? fm['message'];
          if (s != null && s.toString().trim().isNotEmpty) return s.toString();
        }
        return first.toString();
      }
      if (errMap['message'] != null) return errMap['message'].toString();
    }
    final rootList = data['non_field_errors'];
    if (rootList is List && rootList.isNotEmpty) {
      final first = rootList.first;
      if (first is String) return first;
    }
  } catch (_) {}
  return data['message']?.toString();
}

/// When extraction fails but body mentions suspended/inactive, return the right message.
String? _getBlockedMessageFromResponse(Map<String, dynamic> data) {
  try {
    final str = data.toString().toLowerCase();
    if (str.contains('inactive') || str.contains('deactivated')) return _kDeactivatedMessage;
    if (str.contains('suspended')) return _kSuspendedMessage;
  } catch (_) {}
  return null;
}

/// Safely converts API/JSON maps (often Map<dynamic, dynamic>) to Map<String, dynamic>.
Map<String, dynamic>? _toStringKeyMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Extracts user_type from login/OTP response. Checks user object, profile_data, and root data.
/// Also checks 'role' as some backends use that field instead of 'user_type'.
String? _extractUserType(dynamic userObj, Map<String, dynamic>? data) {
  String? getFromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final t = m['user_type'] as String? ?? m['role'] as String?;
    if (t != null) {
      final s = t.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
  final map = _toStringKeyMap(userObj);
  if (map != null) {
    final t = getFromMap(map);
    if (t != null) return t;
    final pd = _toStringKeyMap(map['profile_data']);
    if (pd != null) {
      final pt = getFromMap(pd);
      if (pt != null) return pt;
    }
  }
  final dataMap = _toStringKeyMap(data);
  return getFromMap(dataMap);
}

/// Extracts whether user must change password before accessing app.
/// Checks explicit backend flags: must_change_password, is_first_login, force_password_change.
/// Returns null when backend does not send any of these (use flow-based fallback).
/// Note: We do NOT use password_changed - many backends default it to false, which would
/// wrongly force all users to change password.
bool? _extractMustChangePassword(Map<String, dynamic>? user) {
  if (user == null) return null;
  final v = user['must_change_password'];
  if (v is bool) return v;
  final first = user['is_first_login'];
  if (first is bool) return first;
  final force = user['force_password_change'];
  if (force is bool) return force;
  return null;
}

/// Extract driver status from user/driver JSON. Must align with Driver model's merge sources:
/// json, profile_data, driver_info, profile_data.driver_info, profile_data.driver.
String? _getDriverStatusFromJson(dynamic json) {
  final map = _toStringKeyMap(json);
  if (map == null) return null;
  final profileData = _toStringKeyMap(map['profile_data']);
  final driverInfo = _toStringKeyMap(map['driver_info']) ??
      _toStringKeyMap(profileData?['driver_info']) ??
      _toStringKeyMap(profileData?['driver']);
  // Check all merge sources (same order as Driver.fromJson)
  final status = map['status'] ??
      profileData?['status'] ??
      driverInfo?['status'];
  if (status != null && status.toString().trim().isNotEmpty) return status.toString();
  final isActive = map['is_active'] ?? profileData?['is_active'] ?? driverInfo?['is_active'];
  if (isActive is bool) return isActive ? 'active' : 'inactive';
  return null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  bool _isCheckingAuth = false;

  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (_isCheckingAuth) {
      print('🔐 DEBUG: Auth check already in progress, skipping...');
      return;
    }

    _isCheckingAuth = true;
    print('🔐 DEBUG: Checking authentication status...');

    try {
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
    } finally {
      _isCheckingAuth = false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔐 DEBUG: Starting login for email: $email');
      print('🔐 DEBUG: Login endpoint: ${AppConfig.loginEndpoint}');

      // Clear any existing tokens before login
      await StorageService.clearAuthTokens();

      // Use client: 'driver_app' so backend can reject non-drivers BEFORE sending OTP
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
          'source': 'mobile',
          'client': 'driver_app',
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
        final data = response.data!;

        // Backend may return 200 with success: false and error in body (e.g. suspended)
        if (data['success'] == false) {
          var msg = _extractErrorFromResponse(data) ?? data['message']?.toString();
          final blockedMsg = _getBlockedMessageFromResponse(data);
          if (blockedMsg != null) {
            msg = blockedMsg;
          } else {
            msg = _normalizeApiError(msg, fallback: 'Login failed');
          }
          state = state.copyWith(isLoading: false, error: msg);
          return false;
        }

        print('🔐 DEBUG: Login successful, processing response data');

        // Block non-drivers BEFORE OTP so admins/parents never reach the OTP screen.
        // Backend must include user_type in login response (user object or root-level).
        final userObj = data['user'] ?? data['user_data'];
        String? userType;
        dynamic statusObj;
        if (userObj != null) {
          userType = _extractUserType(userObj, data);
          statusObj = userObj;
        } else {
          userType = _extractUserType(data, data);
        }
        if (userType != null && !_isAllowedUserType(userType)) {
          print('🔐 DEBUG: User type "$userType" not allowed - blocking before OTP');
          state = state.copyWith(
            isLoading: false,
            error: _kNonDriverBlockedMessage,
            otpId: null,
            registrationEmail: null,
          );
          return false;
        }
        if (statusObj != null) {
          final driverStatus = _getDriverStatusFromJson(statusObj);
          if (!_isDriverActive(driverStatus)) {
            print('🔐 DEBUG: Driver status "$driverStatus" - blocking before OTP');
            state = state.copyWith(
              isLoading: false,
              error: _getDriverStatusBlockedMessage(driverStatus),
              otpId: null,
              registrationEmail: null,
            );
            return false;
          }
        }
        print('🔐 DEBUG: User type "$userType" allowed (driver) - proceeding to OTP');

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
        final displayError = (response.error != null && response.error!.contains('OTP'))
            ? response.error!
            : _normalizeApiError(response.error, fallback: 'Login failed');
        state = state.copyWith(isLoading: false, error: displayError);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _normalizeApiError(e.toString(), fallback: 'Login failed: $e'),
      );
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

  /// Shared logic: validate user, persist profile, set auth state from OTP response user.
  /// Returns true if auth succeeded; false if user type or status blocked.
  Future<bool> _finalizeAuthFromOtpUser(Map<String, dynamic> user) async {
    final userType = user['user_type'] as String? ?? user['role'] as String?;
    if (!_isAllowedUserType(userType)) {
      await StorageService.clearAuthTokens();
      state = state.copyWith(
        isLoading: false,
        error: _kNonDriverBlockedMessage,
        otpId: null,
      );
      return false;
    }
    final driverStatus = _getDriverStatusFromJson(user);
    if (!_isDriverActive(driverStatus)) {
      await StorageService.clearAuthTokens();
      state = state.copyWith(
        isLoading: false,
        error: _getDriverStatusBlockedMessage(driverStatus),
        otpId: null,
      );
      return false;
    }
    await StorageService.saveUserProfile(user);
    final idForApi = user['driver_id'] ?? user['id'];
    if (idForApi is int) {
      await StorageService.saveDriverId(idForApi);
    }
    final driver = Driver.fromJson(user);
    final mustChange = _extractMustChangePassword(_toStringKeyMap(user));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      driver: driver,
      profileRawData: user,
      error: null,
      otpId: null,
      mustChangePassword: mustChange,
    );
    return true;
  }

  /// Extracts user/driver object from profile API response.
  /// Handles: { success, user }, { data: { user } }, { data: {...} }, or flat object.
  Map<String, dynamic>? _extractUserFromResponse(dynamic data) {
    final map = _toStringKeyMap(data);
    if (map == null || map.isEmpty) return null;
    // Backend: { success: true, user: {...} }
    final user = _toStringKeyMap(map['user']);
    if (user != null && user.isNotEmpty) return user;
    // { data: { user: {...} } } or { data: {...} } where data is the user
    final nested = _toStringKeyMap(map['data']);
    if (nested != null && nested.isNotEmpty) {
      final nestedUser = _toStringKeyMap(nested['user']);
      if (nestedUser != null && nestedUser.isNotEmpty) return nestedUser;
      // data itself might be the user (has id, email)
      if (nested['id'] != null && nested['email'] != null) return nested;
    }
    // Flat object (has id, email)
    if (map['id'] != null && map['email'] != null) return map;
    // Driver wrappers
    return _toStringKeyMap(map['driver']) ??
        _toStringKeyMap(map['driver_profile']) ??
        _toStringKeyMap(map['profile']);
  }

  Future<void> _loadDriverProfile() async {
    try {
      final token = StorageService.getAuthToken();
      print(
        '🔐 DEBUG: Auth token exists: ${token != null && token.isNotEmpty}',
      );

      Map<String, dynamic>? driverData;
      ApiResponse<Map<String, dynamic>>? lastResponse;

      // 1. Try /drivers/profile/ first (driver-specific endpoint)
      print(
        '🔐 DEBUG: Trying ${AppConfig.driverProfileEndpoint}',
      );
      var response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.driverProfileEndpoint,
      );
      lastResponse = response;
      if (response.success && response.data != null) {
        final data = response.data!;
        driverData = _toStringKeyMap(data['driver']) ??
            _toStringKeyMap(data['driver_profile']) ??
            _extractUserFromResponse(data);
        if (driverData != null && driverData.isNotEmpty) {
          print('🔐 DEBUG: Got data from /drivers/profile/');
        }
      }

      // 2. FALLBACK: GET /api/v1/users/me/ - User Profile API
      if (driverData == null || driverData.isEmpty) {
        print(
          '🔐 DEBUG: Trying ${AppConfig.profileEndpoint}',
        );
        response = await ApiService.get<Map<String, dynamic>>(
          AppConfig.profileEndpoint,
        );
        lastResponse = response;
        if (response.success && response.data != null) {
          driverData = _extractUserFromResponse(response.data!);
          if (driverData != null && driverData.isNotEmpty) {
            print('🔐 DEBUG: Got data from /users/me/');
          }
        }
      }

      // 3. FALLBACK: Load from cached profile when API fails
      // Only skip cache on explicit 401/403 - avoid false positives from error strings
      final isAuthFailure = lastResponse?.statusCode == 401 || lastResponse?.statusCode == 403;
      if ((driverData == null || driverData.isEmpty) &&
          token != null &&
          !isAuthFailure) {
        final cached = StorageService.getUserProfile();
        if (cached != null && cached.isNotEmpty) {
          driverData = _extractUserFromResponse(cached) ?? cached;
          if (driverData != null) {
            print('🔐 DEBUG: Using cached profile');
          }
        }
      }

      // 3b. MERGE cached profile for missing fields (license_number, date_of_birth, address)
      // Backend may not return these - use locally saved data from Edit Profile
      if (driverData != null && token != null) {
        final cached = StorageService.getUserProfile();
        if (cached != null && cached.isNotEmpty) {
          final cachedUser = _extractUserFromResponse(cached) ?? cached;
          final missingAddress = driverData!['address'] == null ||
              (driverData['address'] as String?)?.isEmpty == true;
          final missingLicense = driverData['license_number'] == null ||
              (driverData['license_number'] as String?)?.isEmpty == true;
          final missingDob = driverData['date_of_birth'] == null;
          if (missingAddress || missingLicense || missingDob) {
            final cachedAddr = cachedUser['address'] ?? cachedUser['residential_address'];
            if (missingAddress && cachedAddr != null && cachedAddr.toString().trim().isNotEmpty) {
              driverData = {...driverData!, 'address': cachedAddr.toString()};
              print('🔐 DEBUG: Merged address from cache');
            }
            final cachedLicense = cachedUser['license_number'] ?? cachedUser['license_no'];
            if (missingLicense && cachedLicense != null && cachedLicense.toString().trim().isNotEmpty) {
              driverData = {...driverData!, 'license_number': cachedLicense.toString()};
              print('🔐 DEBUG: Merged license_number from cache');
            }
            final cachedDob = cachedUser['date_of_birth'] ?? cachedUser['dob'];
            if (missingDob && cachedDob != null) {
              driverData = {...driverData!, 'date_of_birth': cachedDob};
              print('🔐 DEBUG: Merged date_of_birth from cache');
            }
          }
        }
      }

      // 4. SUPPLEMENT: Always fetch full driver details from /users/:id/ and /drivers/:id/
      // Desktop uses these endpoints and they return vehicle assignment - we need the same data
      final userId = driverData?['id'] ?? driverData?['user_id'];
      final driverId = driverData?['driver_id'];
      final pdCheck = _toStringKeyMap(driverData?['profile_data']);
      final diCheck = _toStringKeyMap(pdCheck?['driver_info'] ?? pdCheck?['driver']);
      final hasVehicle = driverData?['assigned_vehicle'] != null ||
          driverData?['vehicle_id'] != null ||
          driverData?['vehicle'] != null ||
          pdCheck?['assigned_vehicle'] != null ||
          pdCheck?['vehicle_id'] != null ||
          diCheck?['assigned_vehicle'] != null ||
          diCheck?['vehicle'] != null;
      final missingLicenseOrDob = driverData != null &&
          ((driverData['license_number'] == null ||
                  (driverData['license_number'] as String?)?.isEmpty == true) ||
              (driverData['date_of_birth'] == null) ||
              (driverData['address'] == null ||
                  (driverData['address'] as String?)?.isEmpty == true));
      final shouldSupplement = missingLicenseOrDob || !hasVehicle;

      if (shouldSupplement) {
        // 4a. Try GET /users/:id/ - Single User API (same as desktop driversAPI.getDriver)
        if (userId != null) {
          final userPath = AppConfig.userDetailsEndpoint.replaceFirst(':id', userId.toString());
          print('🔐 DEBUG: Supplementing with Users API $userPath (license/dob/vehicle)');
          final userResp = await ApiService.get<Map<String, dynamic>>(userPath);
          if (userResp.success && userResp.data != null && userResp.data!.isNotEmpty) {
            final raw = userResp.data!;
            final details = _extractUserFromResponse(raw) ?? _toStringKeyMap(raw);
            if (details != null) {
              driverData = {...driverData!, ...details};
              final pd = _toStringKeyMap(details['profile_data']);
              if (pd != null) {
                driverData = {...driverData!, ...pd};
                final di = _toStringKeyMap(pd['driver_info'] ?? pd['driver']);
                if (di != null) driverData = {...driverData!, ...di};
              }
            }
            print('🔐 DEBUG: Merged from Users API: license=${driverData!['license_number']}, dob=${driverData['date_of_birth']}, address=${driverData['address']}');
          }
        }

        // 4b. Try GET /drivers/:id/ - use driver_id if available, else user_id (same as desktop)
        final idToTry = driverId ?? userId;
        if (idToTry != null) {
          final driverPath = '${AppConfig.driverDetailsEndpoint}$idToTry/';
          print('🔐 DEBUG: Supplementing with Drivers API $driverPath');
          final driverResp = await ApiService.get<Map<String, dynamic>>(driverPath);
          if (driverResp.success &&
              driverResp.data != null &&
              driverResp.data!.isNotEmpty) {
            final raw = driverResp.data!;
            final details = _toStringKeyMap(raw['driver']) ??
                _toStringKeyMap(raw['driver_profile']) ??
                _toStringKeyMap(raw);
            if (details != null) {
              driverData = {...driverData!, ...details};
              final pd = _toStringKeyMap(details['profile_data']);
              if (pd != null) {
                driverData = {...driverData!, ...pd};
                final di = _toStringKeyMap(pd['driver_info'] ?? pd['driver']);
                if (di != null) driverData = {...driverData!, ...di};
              }
            }
            print('🔐 DEBUG: Merged from /drivers/:id/: license=${driverData!['license_number']}, dob=${driverData['date_of_birth']}, address=${driverData['address']}');
          }
        }
      }

      print('🔐 DEBUG: Profile load - success: ${driverData != null}');
      if (driverData != null) {
        print('🔐 DEBUG: Driver data keys: ${driverData.keys.toList()}');
        print('🔐 DEBUG: license_number=${driverData['license_number']}, date_of_birth=${driverData['date_of_birth']}, address=${driverData['address']}');
      }

      if (driverData != null && driverData.isNotEmpty) {
        final userType = driverData['user_type'] as String? ?? driverData['role'] as String?;
        if (!_isAllowedUserType(userType)) {
          print('🔐 DEBUG: User type "$userType" not allowed in driver app');
          await logout();
          state = state.copyWith(
            isLoading: false,
            error: _kNonDriverBlockedMessage,
          );
          return;
        }

        print('🔐 DEBUG: Driver data found: $driverData');
        // Check status from raw data first (catches nested profile_data.driver_info.status)
        final rawStatus = _getDriverStatusFromJson(driverData);
        final driver = Driver.fromJson(driverData);

        // Block suspended/deactivated drivers from accessing the app
        if (!_isDriverActive(rawStatus ?? driver.status)) {
          print('🔐 DEBUG: Driver account not active (status: ${driver.status})');
          await logout();
          state = state.copyWith(
            isLoading: false,
            error: _getDriverStatusBlockedMessage(driver.status),
          );
          return;
        }

        print('🔐 DEBUG: Driver created successfully: ${driver.fullName}');

        // Guard: interceptor may have logged us out already - do not overwrite
        if (!state.isAuthenticated && state.error != null) {
          print('🔐 DEBUG: Logout already in progress, skipping profile success');
          return;
        }

        // Prefer driver_id (drivers table) for API calls - trips/assignments use drivers.id
        final pd = _toStringKeyMap(driverData['profile_data']);
        final idForApi = driverData['driver_id'] ??
            pd?['driver_id'] ??
            pd?['driver_info']?['driver_id'] ??
            driver.id;
        await StorageService.saveDriverId(idForApi is int ? idForApi : driver.id);
        await StorageService.saveUserProfile(driverData);

        final mustChange = _extractMustChangePassword(driverData);
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          driver: driver,
          profileRawData: driverData,
          error: null,
          mustChangePassword: mustChange,
        );
        print('🔐 DEBUG: Profile loaded successfully');
      } else {
        final lastError = lastResponse?.error ?? 'No profile data returned';
        print('🔐 DEBUG: Profile load failed: $lastError');

        // Do NOT auto-logout - user controls when to end session
        // Just clear loading and optionally set error; keep user logged in
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load profile: $lastError',
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

  Future<void> logout({
    bool preserveRegistrationState = false,
    String? suspensionError,
  }) async {
    // CRITICAL: Set state FIRST (synchronously) so UI blocks immediately - suspended user cannot use app
    if (preserveRegistrationState && state.registrationEmail != null) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        driver: null,
        error: null,
        otpId: null,
      );
    } else if (suspensionError != null && suspensionError.isNotEmpty) {
      state = AuthState(error: suspensionError);
    } else {
      state = const AuthState();
    }
    print('🔐 DEBUG: User logged out, clearing auth state');

    try {
      final token = StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.post(AppConfig.logoutEndpoint);
      }
    } catch (e) {
      // Continue with logout even if API call fails
    }

    await StorageService.clearAuthTokens();
    await StorageService.clearUserProfile();
    await StorageService.clearDriverId();
    await StorageService.clearCurrentTrip();
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
          'otp': {
            'otp_type': 'login',
          },
          'source': 'mobile',
          'device_info': {
            'user_agent': 'Flutter (${Platform.operatingSystem})',
            'device_type': 'mobile',
          },
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        if (data['success'] == false) {
          final msg = _extractErrorFromResponse(data);
          await StorageService.clearAuthTokens();
          state = state.copyWith(
            isLoading: false,
            error: _normalizeApiError(msg, fallback: 'OTP verification failed'),
            otpId: null,
          );
          return false;
        }

        final tokens = _toStringKeyMap(data['tokens']);

        if (tokens != null) {
          await StorageService.saveAuthToken(tokens['access'] ?? '');
          await StorageService.saveRefreshToken(tokens['refresh'] ?? '');
        }

        // If user object is present, use it to finalize auth without another API call
        final user = _toStringKeyMap(data['user']);
        if (user != null && user.isNotEmpty) {
          final ok = await _finalizeAuthFromOtpUser(user);
          if (ok) print('🔐 DEBUG: OTP verification completed with user data');
          return ok;
        }

        // Fallback: if no user in response, try loading profile endpoint
        print('🔐 DEBUG: No user data in OTP response, loading profile...');
        try {
          await _loadDriverProfile();
          // Only return true if profile loading succeeded
          if (state.isAuthenticated) {
            state = state.copyWith(otpId: null);
            return true;
          } else {
            // Profile loading failed, don't proceed
            return false;
          }
        } catch (e) {
          print('🔐 DEBUG: Profile loading failed: $e');
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load profile after OTP verification: $e',
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _normalizeApiError(response.error, fallback: 'OTP verification failed'),
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _normalizeApiError(e.toString(), fallback: 'OTP verification failed: $e'),
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
          'otp': {
            'otp_type': 'register',
          },
          'source': 'mobile',
          'device_info': {
            'user_agent': 'Flutter (${Platform.operatingSystem})',
            'device_type': 'mobile',
          },
        },
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        if (data['success'] == false) {
          final msg = _extractErrorFromResponse(data);
          await StorageService.clearAuthTokens();
          state = state.copyWith(
            isLoading: false,
            error: _normalizeApiError(msg, fallback: 'OTP verification failed'),
            otpId: null,
          );
          return false;
        }

        final tokens = _toStringKeyMap(data['tokens']);

        if (tokens != null) {
          await StorageService.saveAuthToken(tokens['access'] ?? '');
          await StorageService.saveRefreshToken(tokens['refresh'] ?? '');
        }

        // If user object is present, use it to finalize auth without another API call
        final user = _toStringKeyMap(data['user']);
        if (user != null && user.isNotEmpty) {
          final ok = await _finalizeAuthFromOtpUser(user);
          if (ok) print('🔐 DEBUG: Registration OTP verification completed with user data');
          return ok;
        }

        // Fallback: if no user in response, try loading profile endpoint
        print(
          '🔐 DEBUG: No user data in registration OTP response, loading profile...',
        );
        try {
          await _loadDriverProfile();
          // Only return true if profile loading succeeded
          if (state.isAuthenticated) {
            state = state.copyWith(otpId: null);
            return true;
          } else {
            // Profile loading failed, don't proceed
            return false;
          }
        } catch (e) {
          print('🔐 DEBUG: Registration profile loading failed: $e');
          state = state.copyWith(
            isLoading: false,
            error:
                'Failed to load profile after registration OTP verification: $e',
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _normalizeApiError(response.error, fallback: 'OTP verification failed'),
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _normalizeApiError(e.toString(), fallback: 'OTP verification failed: $e'),
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
          if (completionResponse.user != null) {
            final userType = completionResponse.user!.userType.apiValue;
            if (!_isAllowedUserType(userType)) {
              state = state.copyWith(
                isLoading: false,
                error: _kNonDriverBlockedMessage,
              );
              return false;
            }
            final driverStatus = _getDriverStatusFromJson(
              completionResponse.user!.toJson(),
            );
            if (!_isDriverActive(driverStatus)) {
              state = state.copyWith(
                isLoading: false,
                error: _getDriverStatusBlockedMessage(driverStatus),
              );
              return false;
            }
          }

          // Save tokens
          await StorageService.saveAuthToken(completionResponse.tokens!.access);
          await StorageService.saveRefreshToken(
            completionResponse.tokens!.refresh,
          );

          // Save user data if available
          Map<String, dynamic>? userMap;
          if (completionResponse.user != null) {
            userMap = completionResponse.user!.toJson();
            await StorageService.saveUserProfile(userMap);
            await StorageService.saveDriverId(completionResponse.user!.id);
          }
          // New users completing registration must change password
          final mustChange = userMap != null
              ? _extractMustChangePassword(userMap)
              : true;

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            driver: completionResponse.user != null
                ? Driver.fromJson(completionResponse.user!.toJson())
                : null,
            profileRawData: userMap,
            error: null,
            otpId: null,
            registrationEmail: null,
            mustChangePassword: mustChange ?? true,
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

  Future<bool> confirmPasswordReset({
    required String token,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = PasswordResetConfirmRequest(
        token: token,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.passwordResetConfirmEndpoint,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final confirmResponse =
            PasswordResetConfirmResponse.fromJson(response.data!);

        if (confirmResponse.success) {
          state = state.copyWith(isLoading: false, error: null);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: confirmResponse.message,
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Password reset confirmation failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password reset confirmation failed: $e',
      );
      return false;
    }
  }

  Future<bool> resendOtp({String? email, int? otpId, String? otpType}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use email from state if not provided
      final emailToUse = email ?? state.registrationEmail;
      if (emailToUse == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Email is required to resend OTP',
        );
        return false;
      }

      // Use otpId from state if not provided
      final otpIdToUse = otpId ?? state.otpId;

      // Determine otp_type - default to 'login' if not provided
      final otpTypeToUse = otpType ?? 'login';

      final requestData = <String, dynamic>{
        'email': emailToUse,
        'otp_type': otpTypeToUse,
      };

      if (otpIdToUse != null) {
        requestData['otp_id'] = otpIdToUse;
      }

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.resendOtpEndpoint,
        data: requestData,
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        // Extract new OTP ID if provided
        int? newOtpId;
        if (data['otp_id'] is int) {
          newOtpId = data['otp_id'] as int;
        } else {
          final nestedData = _toStringKeyMap(data['data']);
          if (nestedData != null && nestedData['otp_id'] is int) {
            newOtpId = nestedData['otp_id'] as int;
          }
        }

        state = state.copyWith(
          isLoading: false,
          error: null,
          otpId: newOtpId ?? state.otpId,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to resend OTP',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resend OTP: $e',
      );
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (state.driver == null) return;

    state = state.copyWith(isLoading: true, error: null);

    ApiResponse<Map<String, dynamic>>? response;

    try {
      // Try PATCH /users/me/ first (User Profile API - standard profile update)
      response = await ApiService.patch<Map<String, dynamic>>(
        AppConfig.profileEndpoint,
        data: updates,
      );

      // Fallback to PUT /drivers/profile/ if PATCH /users/me/ fails (404, 405, etc.)
      if (!response.success || response.data == null) {
        response = await ApiService.put<Map<String, dynamic>>(
          AppConfig.driverProfileEndpoint,
          data: updates,
        );
      }

      if (response.success && response.data != null) {
        final data = response.data!;
        final driverJson = _extractUserFromResponse(data) ??
            _toStringKeyMap(data['driver']) ??
            _toStringKeyMap(data['driver_profile']) ??
            _toStringKeyMap(data) ??
            <String, dynamic>{};

        // Always merge updates into response - backend may not return address, license_number, date_of_birth
        final mergedJson = <String, dynamic>{
          ...driverJson,
          ...updates,
          'phone': updates['phone'] ?? updates['phone_number'] ?? driverJson['phone'] ?? driverJson['phone_number'],
          'phone_number': updates['phone_number'] ?? updates['phone'] ?? driverJson['phone_number'] ?? driverJson['phone'],
          'address': updates['address'] ?? driverJson['address'] ?? driverJson['residential_address'],
          'license_number': updates['license_number'] ?? driverJson['license_number'] ?? driverJson['license_no'],
          'date_of_birth': updates['date_of_birth'] ?? driverJson['date_of_birth'] ?? driverJson['dob'],
          'emergency_contact': updates['emergency_contact'] ?? updates['emergency_contact_name'] ?? driverJson['emergency_contact'] ?? driverJson['emergency_contact_name'],
          'emergency_contact_name': updates['emergency_contact_name'] ?? updates['emergency_contact'] ?? driverJson['emergency_contact_name'] ?? driverJson['emergency_contact'],
          'emergency_phone': updates['emergency_phone'] ?? updates['emergency_contact_phone'] ?? driverJson['emergency_phone'] ?? driverJson['emergency_contact_phone'],
          'emergency_contact_phone': updates['emergency_contact_phone'] ?? updates['emergency_phone'] ?? driverJson['emergency_contact_phone'] ?? driverJson['emergency_phone'],
        };
        mergedJson.removeWhere((_, v) => v == null);

        Driver updatedDriver;
        try {
          updatedDriver = Driver.fromJson(mergedJson);
        } catch (_) {
          final current = state.driver!;
          updatedDriver = current.copyWith(
            phone: updates['phone'] ?? updates['phone_number'] ?? current.phone,
            address: updates['address']?.toString() ?? current.address,
            licenseNumber: updates['license_number']?.toString() ?? current.licenseNumber,
            dateOfBirth: updates['date_of_birth'] != null ? DateTime.tryParse(updates['date_of_birth'].toString()) : current.dateOfBirth,
            emergencyContact: updates['emergency_contact'] ?? updates['emergency_contact_name'] ?? current.emergencyContact,
            emergencyPhone: updates['emergency_phone'] ?? updates['emergency_contact_phone'] ?? current.emergencyPhone,
          );
        }

        await StorageService.saveUserProfile(updatedDriver.toJson());

        state = state.copyWith(
          isLoading: false,
          driver: updatedDriver,
          profileRawData: mergedJson,
          error: null,
        );
      } else {
        // API failed - still apply updates locally so user sees their data
        final current = state.driver!;
        final localDriver = current.copyWith(
          phone: updates['phone'] ?? updates['phone_number'] ?? current.phone,
          address: (updates['address'] ?? updates['residential_address'])?.toString() ?? current.address,
          licenseNumber: (updates['license_number'] ?? updates['license_no'])?.toString() ?? current.licenseNumber,
          dateOfBirth: (updates['date_of_birth'] != null ? DateTime.tryParse(updates['date_of_birth'].toString()) : null) ?? current.dateOfBirth,
          emergencyContact: (updates['emergency_contact'] ?? updates['emergency_contact_name'])?.toString() ?? current.emergencyContact,
          emergencyPhone: (updates['emergency_phone'] ?? updates['emergency_contact_phone'])?.toString() ?? current.emergencyPhone,
        );
        await StorageService.saveUserProfile(localDriver.toJson());
        state = state.copyWith(
          isLoading: false,
          driver: localDriver,
          profileRawData: localDriver.toJson(),
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

/// Raw profile data from API response - use to display all details from backend
final profileRawDataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).profileRawData;
});
