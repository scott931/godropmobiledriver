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
                    'Enter the full QR payload (e.g. STU_…) from the student card.',
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
                labelText: 'Full QR code data',
                hintText: 'STU_…',
                prefixIcon: const Icon(Icons.qr_code),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) => _processQRCode(value),
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
      _showErrorDialog('Please enter the full QR code string');
      return;
    }

    try {
      final result = await ref.read(tripProvider.notifier).verifyCheckinWithQrCode(
            qrCodeData: code.trim(),
            isPickup: _isCheckIn,
          );

      if (!mounted) return;
      if (result.success) {
        _showSuccessDialog();
        _qrCodeController.clear();
      } else {
        _showErrorDialog(result.message ?? 'Verification failed');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog() {
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
        content: Text(
          _isCheckIn
              ? 'Student verified and recorded on the bus.'
              : 'Drop-off verified successfully.',
        ),
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

  void _showStudentList() {
    context.pop();
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Help'),
        content: const Text(
          'The app sends the full QR string to the server (POST /checkin/verify/qr-code/). '
          'Use the exact value encoded on the student card (e.g. STU_{id}_{timestamp}_{hex}). '
          'Starting an active trip helps attach vehicle and route to the check-in.',
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
