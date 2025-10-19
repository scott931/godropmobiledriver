import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  const QRScannerScreen({super.key});

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  MobileScannerController? controller;
  bool _isCheckIn = true;
  String? _lastScannedCode;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showPermissionDialog();
        return;
      }

      // Initialize scanner
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        formats: const [BarcodeFormat.qrCode],
      );

      setState(() {});
      print('📷 QR Scanner: Scanner initialized');
    } catch (e) {
      print('📷 QR Scanner: Scanner initialization failed: $e');
      _showErrorDialog('Failed to initialize scanner: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('This app needs camera access to scan QR codes.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isCheckIn ? 'Student Check-in' : 'Student Check-out'),
        backgroundColor: Colors.black,
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
          if (controller != null) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => controller!.toggleTorch(),
              tooltip: 'Toggle Flash',
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => controller!.switchCamera(),
              tooltip: 'Switch Camera',
            ),
          ],
        ],
      ),
      body: controller == null ? _buildLoadingBody() : _buildScannerBody(),
    );
  }

  Widget _buildLoadingBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          const Text(
            'Initializing Scanner...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _initializeScanner,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBody() {
    return Stack(
      children: [
        // Scanner View
        MobileScanner(controller: controller!, onDetect: _onDetect),

        // Scanning Frame
        Center(
          child: Container(
            width: 250.w,
            height: 250.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isCheckIn ? Colors.green : Colors.red,
                width: 4,
              ),
            ),
          ),
        ),

        // Instructions
        Positioned(
          top: 20.h,
          left: 16.w,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Icon(
                  _isCheckIn ? Icons.login : Icons.logout,
                  color: _isCheckIn ? Colors.green : Colors.red,
                  size: 32.w,
                ),
                SizedBox(height: 8.h),
                Text(
                  _isCheckIn ? 'Student Check-in' : 'Student Check-out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Position QR code within the frame',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Action Buttons
        Positioned(
          bottom: 30.h,
          left: 16.w,
          right: 16.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle Button
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16.h),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCheckIn = !_isCheckIn;
                    });
                  },
                  icon: Icon(_isCheckIn ? Icons.logout : Icons.login),
                  label: Text(
                    _isCheckIn ? 'Switch to Check-out' : 'Switch to Check-in',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCheckIn ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showManualEntryDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Manual Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showStudentList,
                      icon: const Icon(Icons.list),
                      label: const Text('Student List'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),

              // Debug Info
              if (_lastScannedCode != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: 16.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last scanned:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _lastScannedCode!,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    _isScanning = true;
    _lastScannedCode = code;

    print('📷 QR Scanner: QR Code detected: $code');
    _processQRCode(code);

    // Reset scanning flag after delay
    Future.delayed(const Duration(seconds: 2), () {
      _isScanning = false;
    });
  }

  Future<void> _processQRCode(String code) async {
    try {
      print('🔍 QR Scanner: Processing QR code: $code');

      final cleanCode = code.trim();
      if (cleanCode.isEmpty) {
        _showErrorDialog('Empty QR code');
        return;
      }

      String? studentId;

      // Try different formats
      if (cleanCode.startsWith('SCHOLATRANSIT_')) {
        studentId = cleanCode.substring(14);
        print('🔍 QR Scanner: SCHOLATRANSIT_ format: $studentId');
      } else if (RegExp(r'^\d+$').hasMatch(cleanCode)) {
        studentId = cleanCode;
        print('🔍 QR Scanner: Numeric format: $studentId');
      } else if (cleanCode.startsWith('{') && cleanCode.endsWith('}')) {
        try {
          final jsonData = json.decode(cleanCode);
          if (jsonData is Map<String, dynamic>) {
            studentId =
                jsonData['student_id']?.toString() ??
                jsonData['id']?.toString() ??
                jsonData['studentId']?.toString();
            print('🔍 QR Scanner: JSON format: $studentId');
          }
        } catch (e) {
          print('🔍 QR Scanner: JSON parsing failed: $e');
        }
      } else {
        final numberMatch = RegExp(r'\d+').firstMatch(cleanCode);
        if (numberMatch != null) {
          studentId = numberMatch.group(0);
          print('🔍 QR Scanner: Extracted number: $studentId');
        } else {
          studentId = cleanCode;
          print('🔍 QR Scanner: Using entire code: $studentId');
        }
      }

      if (studentId != null && studentId.isNotEmpty) {
        final finalStudentId = studentId.trim();
        if (finalStudentId.isEmpty) {
          _showErrorDialog('Invalid student ID: Empty after processing');
          return;
        }

        print('🔍 QR Scanner: Final student ID: $finalStudentId');
        await _processStudentAction(finalStudentId);
      } else {
        print('🔍 QR Scanner: No student ID could be extracted');
        _showInvalidCodeDialog();
      }
    } catch (e) {
      print('🔍 QR Scanner: Error: $e');
      _showErrorDialog('Error processing QR code: $e');
    }
  }

  Future<void> _processStudentAction(String studentId) async {
    try {
      print(
        '🔍 QR Scanner: Processing ${_isCheckIn ? 'check-in' : 'check-out'} for student: $studentId',
      );

      final success = await ref
          .read(tripProvider.notifier)
          .checkInStudent(studentId);

      if (mounted) {
        if (success) {
          print(
            '✅ QR Scanner: Student ${_isCheckIn ? 'check-in' : 'check-out'} successful',
          );
          _showSuccessDialog(
            studentId,
            _isCheckIn ? 'checked in' : 'checked out',
          );
        } else {
          print(
            '❌ QR Scanner: Student ${_isCheckIn ? 'check-in' : 'check-out'} failed',
          );
          _showErrorDialog('Student not found or not assigned to current trip');
        }
      }
    } catch (e) {
      print(
        '💥 QR Scanner: Exception during ${_isCheckIn ? 'check-in' : 'check-out'}: $e',
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
          'Please scan a valid student QR code.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final studentIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Student ${_isCheckIn ? 'Check-in' : 'Check-out'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the student ID manually:'),
            SizedBox(height: 16.h),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                hintText: 'Enter student ID',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                studentIdController.text = '12345';
              },
              child: const Text('Test with: 12345'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              if (studentIdController.text.isNotEmpty) {
                print('🧪 Manual Test: ${studentIdController.text}');
                _processQRCode(studentIdController.text);
              }
            },
            child: Text(_isCheckIn ? 'Check In' : 'Check Out'),
          ),
        ],
      ),
    );
  }

  void _showStudentList() {
    context.pop();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
