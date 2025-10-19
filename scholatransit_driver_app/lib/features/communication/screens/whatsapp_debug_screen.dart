import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/whatsapp_service.dart';

class WhatsAppDebugScreen extends StatefulWidget {
  const WhatsAppDebugScreen({super.key});

  @override
  State<WhatsAppDebugScreen> createState() => _WhatsAppDebugScreenState();
}

class _WhatsAppDebugScreenState extends State<WhatsAppDebugScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+254717127082'; // Default to driver phone
    _messageController.text =
        'Hello! This is a test message from the school bus app.';
    _runDebugTests();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _runDebugTests() {
    setState(() {
      _debugInfo = 'Running WhatsApp Debug Tests...\n\n';
    });

    // Test phone number validation
    final driverPhone = WhatsAppService.getDefaultDriverPhone();
    final adminPhone = WhatsAppService.getDefaultAdminPhone();

    setState(() {
      _debugInfo += 'Driver Phone: $driverPhone\n';
      _debugInfo +=
          'Driver Valid: ${WhatsAppService.isValidPhoneNumber(driverPhone)}\n\n';

      _debugInfo += 'Admin Phone: $adminPhone\n';
      _debugInfo +=
          'Admin Valid: ${WhatsAppService.isValidPhoneNumber(adminPhone)}\n\n';

      _debugInfo += 'Custom Phone: ${_phoneController.text}\n';
      _debugInfo +=
          'Custom Valid: ${WhatsAppService.isValidPhoneNumber(_phoneController.text)}\n\n';
    });
  }

  Future<void> _testWhatsApp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _debugInfo += 'ERROR: Please enter a phone number\n');
      return;
    }

    setState(() {
      _isLoading = true;
      _debugInfo += 'Testing WhatsApp launch...\n';
    });

    try {
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: _phoneController.text.trim(),
        message: _messageController.text.trim(),
      );

      setState(() {
        _debugInfo += success
            ? 'SUCCESS: WhatsApp launched!\n'
            : 'FAILED: Could not launch WhatsApp\n';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo += 'ERROR: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDriverWhatsApp() async {
    setState(() {
      _isLoading = true;
      _debugInfo += 'Testing Driver WhatsApp...\n';
    });

    try {
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: WhatsAppService.getDefaultDriverPhone(),
        message: 'Hello! This is a test message for the driver.',
      );

      setState(() {
        _debugInfo += success
            ? 'SUCCESS: Driver WhatsApp launched!\n'
            : 'FAILED: Could not launch driver WhatsApp\n';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo += 'ERROR: $e\n';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAdminWhatsApp() async {
    setState(() {
      _isLoading = true;
      _debugInfo += 'Testing Admin WhatsApp...\n';
    });

    try {
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: WhatsAppService.getDefaultAdminPhone(),
        message: 'Hello! This is a test message for the admin.',
      );

      setState(() {
        _debugInfo += success
            ? 'SUCCESS: Admin WhatsApp launched!\n'
            : 'FAILED: Could not launch admin WhatsApp\n';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo += 'ERROR: $e\n';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Debug'),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'WhatsApp Debug Console',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            // Phone number input
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 8.h),

            // Message input
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16.h),

            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Test Custom'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testDriverWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Driver'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAdminWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Admin'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Debug info
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: GoogleFonts.robotoMono(fontSize: 12.sp),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Instructions
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Instructions:',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '1. Make sure WhatsApp is installed\n'
                    '2. Test with your own phone number first\n'
                    '3. Check the debug output for errors\n'
                    '4. If WhatsApp doesn\'t open, check device settings',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
