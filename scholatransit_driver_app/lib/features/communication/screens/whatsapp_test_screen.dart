import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/whatsapp_service.dart';

class WhatsAppTestScreen extends StatefulWidget {
  const WhatsAppTestScreen({super.key});

  @override
  State<WhatsAppTestScreen> createState() => _WhatsAppTestScreenState();
}

class _WhatsAppTestScreenState extends State<WhatsAppTestScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _messageController.text =
        'Hello! This is a test message from the school bus app.';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _testWhatsApp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _result = 'Please enter a phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: _phoneController.text.trim(),
        message: _messageController.text.trim(),
      );

      setState(() {
        _result = success
            ? 'WhatsApp launched successfully!'
            : 'Failed to launch WhatsApp';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDefaultDriver() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: WhatsAppService.getDefaultDriverPhone(),
        message: 'Hello! This is a test message for the driver.',
      );

      setState(() {
        _result = success
            ? 'Driver WhatsApp launched!'
            : 'Failed to launch driver WhatsApp';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDefaultAdmin() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: WhatsAppService.getDefaultAdminPhone(),
        message: 'Hello! This is a test message for the admin.',
      );

      setState(() {
        _result = success
            ? 'Admin WhatsApp launched!'
            : 'Failed to launch admin WhatsApp';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Test'),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'WhatsApp Integration Test',
              style: GoogleFonts.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // Custom phone number test
            Text(
              'Test with Custom Phone Number:',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (with country code)',
                hintText: '+1234567890',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _testWhatsApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Custom WhatsApp'),
            ),
            SizedBox(height: 24.h),

            // Default numbers test
            Text(
              'Test Default Numbers:',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testDefaultDriver,
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
                    onPressed: _isLoading ? null : _testDefaultAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Admin'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Result display
            if (_result != null) ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color:
                      _result!.contains('successfully') ||
                          _result!.contains('launched')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color:
                        _result!.contains('successfully') ||
                            _result!.contains('launched')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _result!,
                  style: GoogleFonts.poppins(
                    color:
                        _result!.contains('successfully') ||
                            _result!.contains('launched')
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Instructions
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '1. Enter a valid phone number with country code (e.g., +1234567890)\n'
                    '2. Make sure WhatsApp is installed on your device\n'
                    '3. Test with your own phone number first\n'
                    '4. The app will open WhatsApp with the pre-filled message',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
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
