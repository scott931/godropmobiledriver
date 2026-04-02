import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/student_model.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Single place for **Scan QR** (opens camera/manual flows) and **PIN entry** check-in.
class StudentCheckinHubScreen extends ConsumerStatefulWidget {
  const StudentCheckinHubScreen({super.key});

  @override
  ConsumerState<StudentCheckinHubScreen> createState() =>
      _StudentCheckinHubScreenState();
}

class _StudentCheckinHubScreenState extends ConsumerState<StudentCheckinHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pinController = TextEditingController();
  final _studentIdController = TextEditingController();
  int? _selectedStudentId; // null until parent picks from trip list
  bool _isPickup = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  final _manualNotesController = TextEditingController();
  bool _manualSubmitting = false;

  @override
  void dispose() {
    _tabController.dispose();
    _pinController.dispose();
    _studentIdController.dispose();
    _manualNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    final pin = _pinController.text.trim();
    int? studentId = _selectedStudentId;
    if (studentId == null && _studentIdController.text.trim().isNotEmpty) {
      studentId = int.tryParse(_studentIdController.text.trim());
    }
    if (studentId == null || studentId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student or enter a valid student ID')),
      );
      return;
    }
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the student PIN (4–6 digits)')),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await ref.read(tripProvider.notifier).verifyCheckinWithPin(
          studentId: studentId,
          pinCode: pin,
          isPickup: _isPickup,
        );
    setState(() => _submitting = false);

    if (!mounted) return;
    if (result.success) {
      _pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student verified — marked present on the bus.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final students = tripState.students;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bus check-in'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
            Tab(icon: Icon(Icons.pin), text: 'PIN'),
            Tab(icon: Icon(Icons.touch_app), text: 'Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScanTab(context),
          _buildPinTab(context, students, tripState.currentTrip),
          _buildManualTab(context, students, tripState.currentTrip),
        ],
      ),
    );
  }

  Widget _buildScanTab(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scan the student QR from the parent app or printed card. The full code is sent to the server — do not type only the student number.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          SizedBox(height: 24.h),
          FilledButton.icon(
            onPressed: () => context.push('/students/qr-scanner'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Open camera scanner'),
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: () => context.push('/students/simple-qr-scanner'),
            icon: const Icon(Icons.keyboard),
            label: const Text('Type or paste full QR string'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinTab(
    BuildContext context,
    List<Student> students,
    Trip? currentTrip,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentTrip == null)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Material(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Text(
                    'Start a trip to load students on this route for quick selection.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          Text(
            'Enter the student PIN the parent reads to you. Pickup = boarding; drop-off = leaving the bus.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          SizedBox(height: 24.h),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Pickup'), icon: Icon(Icons.login)),
              ButtonSegment(value: false, label: Text('Drop-off'), icon: Icon(Icons.logout)),
            ],
            selected: {_isPickup},
            onSelectionChanged: (Set<bool> s) {
              setState(() => _isPickup = s.first);
            },
          ),
          SizedBox(height: 20.h),
          if (students.isNotEmpty)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Student on this trip',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedStudentId,
                  hint: const Text('Choose…'),
                  items: students
                      .map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v),
                ),
              ),
            )
          else
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID (numeric)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          SizedBox(height: 16.h),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: _submitting ? null : _submitPin,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitManual() async {
    int? studentId = _selectedStudentId;
    if (studentId == null && _studentIdController.text.trim().isNotEmpty) {
      studentId = int.tryParse(_studentIdController.text.trim());
    }
    if (studentId == null || studentId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a student or enter a valid student ID')),
      );
      return;
    }

    setState(() => _manualSubmitting = true);
    final result = await ref.read(tripProvider.notifier).verifyCheckinManual(
          studentId: studentId,
          isPickup: _isPickup,
          notes: _manualNotesController.text.trim().isEmpty
              ? null
              : _manualNotesController.text.trim(),
        );
    setState(() => _manualSubmitting = false);

    if (!mounted) return;
    if (result.success) {
      _manualNotesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in recorded (manual).')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Check-in failed')),
      );
    }
  }

  Widget _buildManualTab(
    BuildContext context,
    List<Student> students,
    Trip? currentTrip,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentTrip == null)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Material(
                color: AppTheme.warningColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Text(
                    'Start a trip first so the server can link this check-in and allow trip completion.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          Text(
            'Select a student and record pickup or drop-off without QR or PIN. '
            'Use when credentials are unavailable; school policy may require a note.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          SizedBox(height: 24.h),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Pickup'), icon: Icon(Icons.login)),
              ButtonSegment(value: false, label: Text('Drop-off'), icon: Icon(Icons.logout)),
            ],
            selected: {_isPickup},
            onSelectionChanged: (Set<bool> s) {
              setState(() => _isPickup = s.first);
            },
          ),
          SizedBox(height: 20.h),
          if (students.isNotEmpty)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Student on this trip',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedStudentId,
                  hint: const Text('Choose…'),
                  items: students
                      .map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.fullName),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v),
                ),
              ),
            )
          else
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID (numeric)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          SizedBox(height: 16.h),
          TextField(
            controller: _manualNotesController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: _manualSubmitting ? null : _submitManual,
            child: _manualSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Record check-in'),
          ),
        ],
      ),
    );
  }
}
