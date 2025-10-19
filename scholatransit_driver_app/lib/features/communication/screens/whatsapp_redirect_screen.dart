import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/whatsapp_service.dart';

class WhatsAppRedirectScreen extends StatefulWidget {
  final String contactName;
  final String contactType; // 'driver', 'parent', 'admin'
  final String? phoneNumber;

  const WhatsAppRedirectScreen({
    super.key,
    required this.contactName,
    required this.contactType,
    this.phoneNumber,
  });

  @override
  State<WhatsAppRedirectScreen> createState() => _WhatsAppRedirectScreenState();
}

class _WhatsAppRedirectScreenState extends State<WhatsAppRedirectScreen> {
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _launchWhatsApp();
  }

  Future<void> _launchWhatsApp() async {
    setState(() => _isLaunching = true);

    try {
      String phoneNumber = widget.phoneNumber ?? _getDefaultPhoneNumber();
      String message = _getDefaultMessage();

      // Check if phone number is valid
      if (!WhatsAppService.isValidPhoneNumber(phoneNumber)) {
        if (mounted) {
          _showInvalidPhoneDialog();
        }
        return;
      }

      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (mounted) {
        if (success) {
          // Wait a moment then go back
          await Future.delayed(const Duration(seconds: 2));
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        } else {
          _showErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  String _getDefaultPhoneNumber() {
    switch (widget.contactType) {
      case 'driver':
        return WhatsAppService.getDefaultDriverPhone();
      case 'admin':
        return WhatsAppService.getDefaultAdminPhone();
      default:
        return '+1234567890';
    }
  }

  String _getDefaultMessage() {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    switch (widget.contactType) {
      case 'driver':
        return 'Hello! This is regarding my child\'s school bus transportation. Time: $timeString';
      case 'admin':
        return 'Hello! I need assistance with school transportation. Time: $timeString';
      default:
        return 'Hello! Time: $timeString';
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'WhatsApp Not Available',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'WhatsApp is not installed on this device. Please install WhatsApp to continue.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInvalidPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Invalid Phone Number',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'The phone number for ${widget.contactName} is not available or invalid. Please contact your administrator to update the contact information.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/conversations');
            }
          },
        ),
        title: Text(
          'Redirecting to WhatsApp',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WhatsApp Icon
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(60.r),
                ),
                child: Icon(Icons.chat, size: 60.w, color: Colors.white),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Opening WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // Subtitle
              Text(
                'Redirecting you to WhatsApp to chat with ${widget.contactName}',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Loading indicator
              if (_isLaunching) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF25D366)),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Launching WhatsApp...',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                // Retry button
                ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Back button
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
