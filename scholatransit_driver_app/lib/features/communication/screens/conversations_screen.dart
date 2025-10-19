import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/whatsapp_service_with_logging.dart';
import '../../../core/services/phone_call_service.dart';
import '../../../core/services/simple_communication_log_service.dart';
import '../../../core/models/communication_log_model.dart';
import 'communication_log_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isCreating = false;
  final TextEditingController _parentPhoneController = TextEditingController();
  List<CommunicationLog> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _loadRecentLogs();
  }

  @override
  void dispose() {
    _parentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentLogs() async {
    try {
      // Ensure service is initialized
      if (!SimpleCommunicationLogService.isInitialized) {
        await SimpleCommunicationLogService.init();
      }

      // Force reload from storage
      await SimpleCommunicationLogService.reloadLogs();
      final recentLogs = SimpleCommunicationLogService.getRecentLogs(limit: 5);

      if (mounted) {
        setState(() {
          _recentLogs = recentLogs;
        });
      }
    } catch (e) {
      print('Error loading recent logs: $e');
    }
  }

  Future<void> _createChatWithParent() async {
    if (_isCreating) return;

    // Show dialog to input parent phone number
    final phoneNumber = await _showParentPhoneDialog();
    if (phoneNumber == null) return; // User cancelled

    setState(() => _isCreating = true);
    await _launchWhatsAppWithParentPhone(phoneNumber);
    setState(() => _isCreating = false);
  }

  Future<String?> _showParentPhoneDialog() async {
    _parentPhoneController.clear();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Parent',
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter parent\'s phone number to start WhatsApp chat',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Phone input field with enhanced design
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _parentPhoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            // Auto-add +254 prefix for Kenyan numbers
                            if (value.isNotEmpty && !value.startsWith('+')) {
                              if (value.startsWith('254')) {
                                _parentPhoneController.text = '+$value';
                                _parentPhoneController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _parentPhoneController.text.length,
                                  ),
                                );
                              } else if (value.startsWith('0') &&
                                  value.length > 1) {
                                // Convert 07xxxxxxxx to +2547xxxxxxxx
                                String newValue = '+254${value.substring(1)}';
                                _parentPhoneController.text = newValue;
                                _parentPhoneController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _parentPhoneController.text.length,
                                  ),
                                );
                              } else if (value.length >= 9 &&
                                  !value.startsWith('+')) {
                                // Auto-add +254 for 9+ digit numbers
                                String newValue = '+254$value';
                                _parentPhoneController.text = newValue;
                                _parentPhoneController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _parentPhoneController.text.length,
                                  ),
                                );
                              }
                            }
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., 0712345678 or +254712345678',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              padding: EdgeInsets.all(12.w),
                              child: Icon(
                                Icons.phone_outlined,
                                color: const Color(0xFF10B981),
                                size: 20.w,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Help text
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF0EA5E9),
                              size: 16.w,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Enter phone number with or without +254 prefix. We\'ll format it automatically.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF0369A1),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Action buttons with modern design
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final phone = _parentPhoneController.text
                                      .trim();
                                  if (phone.isNotEmpty) {
                                    Navigator.of(context).pop(phone);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat, size: 18.w),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Start Chat',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCallParentDialog() async {
    _parentPhoneController.clear();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Call Parent',
                              style: GoogleFonts.poppins(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter parent\'s phone number to make a call',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    children: [
                      // Phone input field with enhanced design
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _parentPhoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            // Auto-add +254 prefix for Kenyan numbers
                            if (value.isNotEmpty && !value.startsWith('+')) {
                              if (value.startsWith('254')) {
                                _parentPhoneController.text = '+$value';
                                _parentPhoneController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _parentPhoneController.text.length,
                                  ),
                                );
                              } else if (value.startsWith('0') &&
                                  value.length > 1) {
                                // Convert 07xxxxxxxx to +2547xxxxxxxx
                                String newValue = '+254${value.substring(1)}';
                                _parentPhoneController.text = newValue;
                                _parentPhoneController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _parentPhoneController.text.length,
                                  ),
                                );
                              } else if (value.length >= 9 &&
                                  !value.startsWith('+')) {
                                // Auto-add +254 for 9+ digit numbers
                                String newValue = '+254$value';
                                _parentPhoneController.text = newValue;
                                _parentPhoneController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _parentPhoneController.text.length,
                                  ),
                                );
                              }
                            }
                          },
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'e.g., 0712345678 or +254712345678',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              padding: EdgeInsets.all(12.w),
                              child: Icon(
                                Icons.phone_outlined,
                                color: const Color(0xFF10B981),
                                size: 20.w,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Help text
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFF0EA5E9).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFF0EA5E9),
                              size: 16.w,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Enter phone number with or without +254 prefix. We\'ll format it automatically.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF0369A1),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Action buttons with modern design
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final phone = _parentPhoneController.text
                                      .trim();
                                  if (phone.isNotEmpty) {
                                    Navigator.of(context).pop(phone);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone, size: 18.w),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Make Call',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((phoneNumber) {
      if (phoneNumber != null) {
        _makePhoneCall(phoneNumber);
      }
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      if (!PhoneCallService.isValidPhoneNumber(phoneNumber)) {
        _showInvalidPhoneDialog();
        return;
      }

      final success = await PhoneCallService.makePhoneCall(
        phoneNumber: phoneNumber,
        contactName: 'Parent',
        studentName: 'Student',
      );

      if (!success && mounted) {
        _showPhoneCallErrorDialog();
      } else if (success) {
        // Refresh recent logs after successful call
        _loadRecentLogs();
      }
    } catch (e) {
      if (mounted) {
        _showPhoneCallErrorDialog();
      }
    }
  }

  void _showPhoneCallErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Make Call'),
        content: const Text(
          'There was an error making the phone call. Please make sure your device supports phone calls and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsAppWithParentPhone(String phoneNumber) async {
    try {
      String message = 'Hello! this is Go Drop Bus driver regarding your child';

      if (!WhatsAppService.isValidPhoneNumber(phoneNumber)) {
        _showInvalidPhoneDialog();
        return;
      }

      // Skip availability check and try to launch directly

      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: phoneNumber,
        message: message,
        contactName: 'Parent',
        studentName: 'Student',
      );

      if (!success && mounted) {
        // Show a more helpful error message
        _showWhatsAppLaunchErrorDialog();
      } else if (success) {
        print('WhatsApp launched successfully');
      }
    } catch (e) {
      if (mounted) {
        _showWhatsAppLaunchErrorDialog();
      }
    }
  }

  Future<void> _createChatWithAdmin() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    // Launch WhatsApp with admin instead of creating a chat
    await _launchWhatsAppWithAdmin();

    setState(() => _isCreating = false);
  }

  Future<void> _launchWhatsAppWithAdmin() async {
    try {
      // Use admin phone number
      String phoneNumber = WhatsAppService.getDefaultAdminPhone();
      String message = 'Hello! this is Go Drop Bus driver';

      // Check if phone number is valid
      if (!WhatsAppService.isValidPhoneNumber(phoneNumber)) {
        _showInvalidPhoneDialog();
        return;
      }

      // Launch WhatsApp
      final success = await WhatsAppService.launchWhatsAppWithMessage(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (!success && mounted) {
        _showWhatsAppErrorDialog();
      }
    } catch (e) {
      if (mounted) {
        _showWhatsAppErrorDialog();
      }
    }
  }

  void _showInvalidPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Phone Number'),
        content: const Text(
          'The parent\'s phone number is not available or invalid. Please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp Not Available'),
        content: const Text(
          'WhatsApp is not installed on this device. Please install WhatsApp to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWhatsAppLaunchErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unable to Launch WhatsApp'),
        content: const Text(
          'There was an error launching WhatsApp. Please make sure WhatsApp is installed on your device and try again. If WhatsApp is installed, try restarting the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
        title: Text(
          'Conversations',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunicationLogScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history, color: Color(0xFF3B82F6)),
              tooltip: 'View Communication Log',
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Always show WhatsApp options instead of loading/error states
    return _buildWhatsAppOptions();
  }

  Widget _buildWhatsAppOptions() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            SizedBox(height: 32.h),

            // Recent Communications Section
            if (_recentLogs.isNotEmpty) ...[
              _buildRecentCommunicationsSection(),
              SizedBox(height: 24.h),
            ],

            // Quick Actions Section
            _buildQuickActionsSection(),
            SizedBox(height: 24.h),

            // Communication Options
            _buildCommunicationOptions(),
            SizedBox(height: 24.h),

            // Communication Log Access
            _buildLogAccessSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Communication',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Connect with parents and admin instantly',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.family_restroom,
                title: 'Parent',
                subtitle: 'Message parent',
                color: const Color(0xFF10B981),
                onTap: _createChatWithParent,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.admin_panel_settings,
                title: 'Admin',
                subtitle: 'Contact admin',
                color: const Color(0xFF3B82F6),
                onTap: _createChatWithAdmin,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreating ? null : onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 28.w),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (_isCreating) ...[
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCommunicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Communications',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunicationLogScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ..._recentLogs.take(3).map((log) => _buildRecentLogCard(log)),
      ],
    );
  }

  Widget _buildRecentLogCard(CommunicationLog log) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: log.success
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _getTypeColor(log.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(log.type.icon, style: TextStyle(fontSize: 16.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.contactName,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  log.phoneNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  _formatDateTime(log.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: log.success
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              log.success ? 'Success' : 'Failed',
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: log.success
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(CommunicationType type) {
    switch (type) {
      case CommunicationType.call:
        return const Color(0xFF10B981);
      case CommunicationType.whatsapp:
        return const Color(0xFF25D366);
      case CommunicationType.sms:
        return const Color(0xFF3B82F6);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildLogAccessSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF667eea), const Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.history, color: Colors.white, size: 24.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'History',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'View all your calls and messages',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunicationLogScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 20.w,
                    ),
                    label: Text(
                      'View All Logs',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommunicationLogScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.analytics, color: Colors.white, size: 20.w),
                  tooltip: 'View Statistics',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Options',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16.h),
        _buildCommunicationCard(
          icon: Icons.phone,
          title: 'Call Parent',
          subtitle: 'Make a direct phone call',
          color: const Color(0xFF10B981),
          onTap: _showCallParentDialog,
        ),
        SizedBox(height: 12.h),
        _buildCommunicationCard(
          icon: Icons.message,
          title: 'SMS Parent',
          subtitle: 'Send text message',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            // TODO: Implement SMS functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('SMS feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunicationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
