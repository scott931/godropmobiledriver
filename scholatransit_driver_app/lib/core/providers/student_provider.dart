import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../models/qrcode_model.dart';
import '../models/pin_model.dart';

class StudentState {
  final bool isLoading;
  final QrCodeInfo? latestQr;
  final List<QrCodeInfo> qrCodes;
  final QrCodeInfo? selectedQr;
  final List<PinInfo> pins;
  final PinInfo? selectedPin;
  final String? error;

  const StudentState({
    this.isLoading = false,
    this.latestQr,
    this.qrCodes = const [],
    this.selectedQr,
    this.pins = const [],
    this.selectedPin,
    this.error,
  });

  StudentState copyWith({
    bool? isLoading,
    QrCodeInfo? latestQr,
    List<QrCodeInfo>? qrCodes,
    QrCodeInfo? selectedQr,
    List<PinInfo>? pins,
    PinInfo? selectedPin,
    String? error,
  }) {
    return StudentState(
      isLoading: isLoading ?? this.isLoading,
      latestQr: latestQr ?? this.latestQr,
      qrCodes: qrCodes ?? this.qrCodes,
      selectedQr: selectedQr ?? this.selectedQr,
      pins: pins ?? this.pins,
      selectedPin: selectedPin ?? this.selectedPin,
      error: error,
    );
  }
}

class StudentNotifier extends StateNotifier<StudentState> {
  StudentNotifier() : super(const StudentState());

  Future<bool> generateStudentQrCode({
    required int studentId,
    required String qrType,
    required String expiresAtIso,
    required bool isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinQrCodesEndpoint,
        data: {
          'student_id': studentId,
          'qr_type': qrType,
          'expires_at': expiresAtIso,
          'is_active': isActive,
        },
      );

      if (response.success && response.data != null) {
        final qr = QrCodeInfo.fromJson(response.data!);
        state = state.copyWith(isLoading: false, latestQr: qr);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to generate QR code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate QR code: $e');
      return false;
    }
  }

  Future<bool> generateStudentPin({
    required int studentId,
    required String pinCode,
    required bool isActive,
    required String expiresAtIso,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinPinsEndpoint,
        data: {
          'student_id': studentId,
          'pin_code': pinCode,
          'is_active': isActive,
          'expires_at': expiresAtIso,
        },
      );
      if (response.success && response.data != null) {
        // Optionally return or store PinInfo; here we just confirm success.
        final _ = PinInfo.fromJson(response.data!);
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to generate PIN',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to generate PIN: $e');
      return false;
    }
  }

  Future<bool> listStudentPins({
    int? studentId,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final query = <String, dynamic>{};
      if (studentId != null) query['student_id'] = studentId;
      if (isActive != null) query['is_active'] = isActive;

      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.checkinPinsEndpoint,
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.success && response.data != null) {
        final list = (response.data!['results'] as List?)
                ?.map((j) => PinInfo.fromJson(j))
                .toList() ??
            [];
        state = state.copyWith(isLoading: false, pins: list);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to list PINs',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to list PINs: $e');
      return false;
    }
  }

  Future<bool> loadPinDetails(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '${AppConfig.checkinPinsEndpoint}$id/',
      );
      if (response.success && response.data != null) {
        final pin = PinInfo.fromJson(response.data!);
        state = state.copyWith(isLoading: false, selectedPin: pin);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load PIN details',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load PIN details: $e');
      return false;
    }
  }

  Future<bool> updateStudentPin({
    required int id,
    required int studentId,
    required bool isActive,
    required String expiresAtIso,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.put<Map<String, dynamic>>(
        '${AppConfig.checkinPinsEndpoint}$id/',
        data: {
          'student_id': studentId,
          'is_active': isActive,
          'expires_at': expiresAtIso,
        },
      );
      if (response.success && response.data != null) {
        final pin = PinInfo.fromJson(response.data!);
        state = state.copyWith(isLoading: false, selectedPin: pin);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to update PIN',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update PIN: $e');
      return false;
    }
  }

  Future<bool> createCheckinSession({
    required int studentId,
    required String checkinType,
    required int vehicleId,
    required int routeId,
    required int stopId,
    required String locationLatLon,
    required String address,
    required String verificationMethod,
    required Map<String, dynamic> verificationData,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinSessionsEndpoint,
        data: {
          'student_id': studentId,
          'checkin_type': checkinType,
          'vehicle': vehicleId,
          'route': routeId,
          'stop': stopId,
          'location': locationLatLon,
          'address': address,
          'verification_method': verificationMethod,
          'verification_data': verificationData,
          'notes': notes,
          'metadata': metadata,
        },
      );
      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to create check-in session',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create check-in session: $e');
      return false;
    }
  }

  Future<bool> createCheckinRule({
    required String name,
    required String checkinType,
    required List<int> vehicleIds,
    required List<int> routeIds,
    required List<int> stopIds,
    required String allowedTimeStart,
    required String allowedTimeEnd,
    required List<String> requiredVerificationMethods,
    required bool allowManualOverride,
    required int geofenceRadius,
    required bool requireLocationVerification,
    required bool isActive,
    required int priority,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinRulesEndpoint,
        data: {
          'name': name,
          'checkin_type': checkinType,
          'vehicle_ids': vehicleIds,
          'route_ids': routeIds,
          'stop_ids': stopIds,
          'allowed_time_start': allowedTimeStart,
          'allowed_time_end': allowedTimeEnd,
          'required_verification_methods': requiredVerificationMethods,
          'allow_manual_override': allowManualOverride,
          'geofence_radius': geofenceRadius,
          'require_location_verification': requireLocationVerification,
          'is_active': isActive,
          'priority': priority,
        },
      );
      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to create check-in rule',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create check-in rule: $e');
      return false;
    }
  }

  Future<bool> listStudentQrCodes({
    int? studentId,
    String? qrType,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final query = <String, dynamic>{};
      if (studentId != null) query['student_id'] = studentId;
      if (qrType != null) query['qr_type'] = qrType;
      if (isActive != null) query['is_active'] = isActive;

      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.checkinQrCodesEndpoint,
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.success && response.data != null) {
        final list = (response.data!['results'] as List?)
                ?.map((j) => QrCodeInfo.fromJson(j))
                .toList() ??
            [];
        state = state.copyWith(isLoading: false, qrCodes: list);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to list QR codes',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to list QR codes: $e');
      return false;
    }
  }

  Future<bool> loadQrCodeDetails(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '${AppConfig.checkinQrCodesEndpoint}$id/',
      );
      if (response.success && response.data != null) {
        final qr = QrCodeInfo.fromJson(response.data!);
        state = state.copyWith(isLoading: false, selectedQr: qr);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load QR code details',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load QR code details: $e');
      return false;
    }
  }

  Future<bool> updateQrCode({
    required int id,
    required int studentId,
    required bool isActive,
    required String expiresAtIso,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.put<Map<String, dynamic>>(
        '${AppConfig.checkinQrCodesEndpoint}$id/',
        data: {
          'student_id': studentId.toString(),
          'is_active': isActive,
          'expires_at': expiresAtIso,
        },
      );
      if (response.success && response.data != null) {
        final qr = QrCodeInfo.fromJson(response.data!);
        state = state.copyWith(isLoading: false, selectedQr: qr);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to update QR code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update QR code: $e');
      return false;
    }
  }
}

final studentProvider = StateNotifierProvider<StudentNotifier, StudentState>((ref) {
  return StudentNotifier();
});


