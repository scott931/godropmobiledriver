import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/school_model.dart';
import '../services/api_service.dart';

class SchoolState {
  final List<School> schools;
  final bool isLoading;
  final String? error;

  const SchoolState({
    this.schools = const [],
    this.isLoading = false,
    this.error,
  });

  SchoolState copyWith({
    List<School>? schools,
    bool? isLoading,
    String? error,
  }) {
    return SchoolState(
      schools: schools ?? this.schools,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SchoolNotifier extends StateNotifier<SchoolState> {
  SchoolNotifier() : super(const SchoolState());

  Future<void> loadSchools() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.schoolsEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final list = (data['results'] as List?)
                ?.map((school) => School.fromJson(school))
                .toList() ??
            [];

        // If no 'results' key, try direct list
        final schoolsList = list.isEmpty && data is List
            ? (data as List)
                .map((school) => School.fromJson(school))
                .toList()
            : list;

        state = state.copyWith(
          isLoading: false,
          schools: schoolsList,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load schools',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load schools: $e',
      );
    }
  }

  /// Find a school by name and return its ID
  /// Returns null if not found
  int? getSchoolIdByName(String schoolName) {
    final school = state.schools.firstWhere(
      (s) => s.name.toLowerCase() == schoolName.toLowerCase(),
      orElse: () => const School(id: -1, name: ''),
    );

    return school.id != -1 ? school.id : null;
  }
}

final schoolProvider =
    StateNotifierProvider<SchoolNotifier, SchoolState>((ref) {
  return SchoolNotifier();
});
