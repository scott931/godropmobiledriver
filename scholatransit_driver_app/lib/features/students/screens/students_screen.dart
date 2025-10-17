import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/student_card.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load students for current trip if available
      final currentTrip = ref.read(tripProvider).currentTrip;
      if (currentTrip != null) {
        ref.read(tripProvider.notifier).loadTripStudents(currentTrip.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.go('/students/qr-scanner'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final currentTrip = tripState.currentTrip;
              if (currentTrip != null) {
                ref
                    .read(tripProvider.notifier)
                    .loadTripStudents(currentTrip.id);
              }
            },
          ),
        ],
      ),
      body: tripState.currentTrip == null
          ? _NoActiveTripState()
          : tripState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tripState.error != null
          ? _ErrorState(error: tripState.error!)
          : tripState.students.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                final currentTrip = tripState.currentTrip;
                if (currentTrip != null) {
                  await ref
                      .read(tripProvider.notifier)
                      .loadTripStudents(currentTrip.id);
                }
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: tripState.students.length,
                itemBuilder: (context, index) {
                  final student = tripState.students[index];
                  return StudentCard(
                    student: student,
                    onStatusUpdate: (status) {
                      ref
                          .read(tripProvider.notifier)
                          .updateStudentStatus(student.id, status);
                    },
                  );
                },
              ),
            ),
      floatingActionButton: tripState.currentTrip != null
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/students/qr-scanner'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }
}

class _NoActiveTripState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64.w,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Active Trip',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start a trip to view students',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64.w, color: AppTheme.textTertiary),
          SizedBox(height: 16.h),
          Text(
            'No Students',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            'Students will appear here when assigned to your trip',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: AppTheme.errorColor),
          SizedBox(height: 16.h),
          Text(
            'Error Loading Students',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              // Retry loading students
              final tripState = ref.read(tripProvider);
              if (tripState.currentTrip != null) {
                ref
                    .read(tripProvider.notifier)
                    .loadTripStudents(tripState.currentTrip!.id);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
