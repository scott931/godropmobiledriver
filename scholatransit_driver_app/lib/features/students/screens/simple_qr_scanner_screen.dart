import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';

class SimpleQRScannerScreen extends ConsumerStatefulWidget {
  const SimpleQRScannerScreen({super.key});

  @override
  ConsumerState<SimpleQRScannerScreen> createState() =>
      _SimpleQRScannerScreenState();
}

class _SimpleQRScannerScreenState extends ConsumerState<SimpleQRScannerScreen> {
  bool _isCheckIn = true;
  final TextEditingController _qrCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isCheckIn ? 'Student Check-in' : 'Student Check-out'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isCheckIn ? Icons.logout : Icons.login),
            onPressed: () {
              setState(() {
                _isCheckIn = !_isCheckIn;
              });
            },
            tooltip: _isCheckIn ? 'Switch to Check-out' : 'Switch to Check-in',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: _isCheckIn
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _isCheckIn ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isCheckIn ? Icons.login : Icons.logout,
                    color: _isCheckIn ? Colors.green : Colors.red,
                    size: 48.w,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _isCheckIn ? 'Student Check-in' : 'Student Check-out',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: _isCheckIn ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Enter the student QR code or ID manually',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // QR Code Input
            TextField(
              controller: _qrCodeController,
              decoration: InputDecoration(
                labelText: 'Student QR Code or ID',
                hintText: 'Enter QR code or student ID',
                prefixIcon: const Icon(Icons.qr_code),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => _processQRCode(value),
            ),

            SizedBox(height: 16.h),

            // Quick Test Buttons
            const Text(
              'Quick Test:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _qrCodeController.text = 'SCHOLATRANSIT_12345';
                  },
                  child: const Text('SCHOLATRANSIT_'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _qrCodeController.text = '12345';
                  },
                  child: const Text('Numeric'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _qrCodeController.text = '{"student_id": "12345"}';
                  },
                  child: const Text('JSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Process Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _processQRCode(_qrCodeController.text),
                icon: Icon(_isCheckIn ? Icons.login : Icons.logout),
                label: Text(
                  _isCheckIn ? 'Check In Student' : 'Check Out Student',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCheckIn ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Alternative Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showStudentList,
                    icon: const Icon(Icons.list),
                    label: const Text('Student List'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showHelp,
                    icon: const Icon(Icons.help),
                    label: const Text('Help'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processQRCode(String code) async {
    if (code.trim().isEmpty) {
      _showErrorDialog('Please enter a QR code or student ID');
      return;
    }

    try {
      print('🔍 Simple QR Scanner: Processing: $code');

      final cleanCode = code.trim();
      String? studentId;

      // Try different formats
      if (cleanCode.startsWith('SCHOLATRANSIT_')) {
        studentId = cleanCode.substring(14);
        print('🔍 Simple QR Scanner: SCHOLATRANSIT_ format: $studentId');
      } else if (RegExp(r'^\d+$').hasMatch(cleanCode)) {
        studentId = cleanCode;
        print('🔍 Simple QR Scanner: Numeric format: $studentId');
      } else if (cleanCode.startsWith('{') && cleanCode.endsWith('}')) {
        try {
          final jsonData = json.decode(cleanCode);
          if (jsonData is Map<String, dynamic>) {
            studentId =
                jsonData['student_id']?.toString() ??
                jsonData['id']?.toString() ??
                jsonData['studentId']?.toString();
            print('🔍 Simple QR Scanner: JSON format: $studentId');
          }
        } catch (e) {
          print('🔍 Simple QR Scanner: JSON parsing failed: $e');
        }
      } else {
        final numberMatch = RegExp(r'\d+').firstMatch(cleanCode);
        if (numberMatch != null) {
          studentId = numberMatch.group(0);
          print('🔍 Simple QR Scanner: Extracted number: $studentId');
        } else {
          studentId = cleanCode;
          print('🔍 Simple QR Scanner: Using entire code: $studentId');
        }
      }

      if (studentId != null && studentId.isNotEmpty) {
        final finalStudentId = studentId.trim();
        if (finalStudentId.isEmpty) {
          _showErrorDialog('Invalid student ID: Empty after processing');
          return;
        }

        print('🔍 Simple QR Scanner: Final student ID: $finalStudentId');
        await _processStudentAction(finalStudentId);
      } else {
        print('🔍 Simple QR Scanner: No student ID could be extracted');
        _showInvalidCodeDialog();
      }
    } catch (e) {
      print('🔍 Simple QR Scanner: Error: $e');
      _showErrorDialog('Error processing QR code: $e');
    }
  }

  Future<void> _processStudentAction(String studentId) async {
    try {
      print(
        '🔍 Simple QR Scanner: Processing ${_isCheckIn ? 'check-in' : 'check-out'} for student: $studentId',
      );

      final success = await ref
          .read(tripProvider.notifier)
          .checkInStudent(studentId);

      if (mounted) {
        if (success) {
          print(
            '✅ Simple QR Scanner: Student ${_isCheckIn ? 'check-in' : 'check-out'} successful',
          );
          _showSuccessDialog(
            studentId,
            _isCheckIn ? 'checked in' : 'checked out',
          );
          _qrCodeController
              .clear(); // Clear the input after successful processing
        } else {
          print(
            '❌ Simple QR Scanner: Student ${_isCheckIn ? 'check-in' : 'check-out'} failed',
          );
          _showErrorDialog('Student not found or not assigned to current trip');
        }
      }
    } catch (e) {
      print(
        '💥 Simple QR Scanner: Exception during ${_isCheckIn ? 'check-in' : 'check-out'}: $e',
      );
      if (mounted) {
        _showErrorDialog(
          'Error ${_isCheckIn ? 'checking in' : 'checking out'} student: $e',
        );
      }
    }
  }

  void _showSuccessDialog(String studentId, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _isCheckIn ? Colors.green : Colors.blue,
            ),
            SizedBox(width: 8.w),
            Text('${_isCheckIn ? 'Check-in' : 'Check-out'} Successful'),
          ],
        ),
        content: Text('Student $studentId has been $action successfully.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8.w),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showInvalidCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningColor),
            SizedBox(width: 8.w),
            const Text('Invalid QR Code'),
          ],
        ),
        content: const Text(
          'This QR code is not valid for student check-in/check-out.\n\n'
          'Supported formats:\n'
          '• SCHOLATRANSIT_[StudentID]\n'
          '• Numeric Student ID\n'
          '• JSON format with student information\n'
          '• Text containing student ID information\n\n'
          'Please enter a valid student QR code.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showStudentList() {
    context.pop();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Help'),
        content: const Text(
          'Enter the student QR code or ID in the text field above.\n\n'
          'Supported formats:\n'
          '• SCHOLATRANSIT_12345\n'
          '• 12345 (numeric ID)\n'
          '• {"student_id": "12345"} (JSON)\n'
          '• Any text containing a number\n\n'
          'Use the test buttons to try different formats.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrCodeController.dispose();
    super.dispose();
  }
}
