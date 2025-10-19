import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/whatsapp_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isCreating = false;
  final TextEditingController _parentPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _parentPhoneController.dispose();
    super.dispose();
  }

  void _showCreateChatDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 8,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 400.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, const Color(0xFFF8FAFC)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 32.w,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  'Start New Conversation',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  'Choose who you want to chat with',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Chat Options
                _buildChatOption(
                  icon: Icons.chat,
                  title: 'WhatsApp Parent',
                  subtitle: 'Open WhatsApp to message parent',
                  onTap: () {
                    Navigator.of(context).pop();
                    _createChatWithParent();
                  },
                  color: const Color(0xFF4CAF50),
                ),
                SizedBox(height: 12.h),

                _buildChatOption(
                  icon: Icons.chat,
                  title: 'WhatsApp Admin',
                  subtitle: 'Open WhatsApp to message admin',
                  onTap: () {
                    Navigator.of(context).pop();
                    _createChatWithAdmin();
                  },
                  color: const Color(0xFF4CAF50),
                ),
                SizedBox(height: 24.h),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, size: 20.w, color: color),
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
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
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
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.phone,
                        size: 24.w,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parent Phone Number',
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Enter parent\'s phone number',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Phone input field
                TextField(
                  controller: _parentPhoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    // Auto-add +254 prefix for Kenyan numbers
                    if (value.isNotEmpty && !value.startsWith('+')) {
                      if (value.startsWith('254')) {
                        _parentPhoneController.text = '+$value';
                        _parentPhoneController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _parentPhoneController.text.length,
                              ),
                            );
                      } else if (value.startsWith('0') && value.length > 1) {
                        // Convert 07xxxxxxxx to +2547xxxxxxxx
                        String newValue = '+254${value.substring(1)}';
                        _parentPhoneController.text = newValue;
                        _parentPhoneController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _parentPhoneController.text.length,
                              ),
                            );
                      } else if (value.length >= 9 && !value.startsWith('+')) {
                        // Auto-add +254 for 9+ digit numbers
                        String newValue = '+254$value';
                        _parentPhoneController.text = newValue;
                        _parentPhoneController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _parentPhoneController.text.length,
                              ),
                            );
                      }
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g., 0712345678 or +254712345678',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final phone = _parentPhoneController.text.trim();
                          if (phone.isNotEmpty) {
                            Navigator.of(context).pop(phone);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Start Chat',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
        actions: [],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateChatDialog,
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat),
        label: const Text('Start Conversation'),
      ),
    );
  }

  Widget _buildBody() {
    // Always show WhatsApp options instead of loading/error states
    return _buildWhatsAppOptions();
  }

  Widget _buildWhatsAppOptions() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // WhatsApp Parent Option
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16.h),
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createChatWithParent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                icon: _isCreating
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.family_restroom, size: 24),
                label: Column(
                  children: [
                    Text(
                      'WhatsApp Parent',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Enter parent\'s phone number',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // WhatsApp Admin Option
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createChatWithAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
                icon: _isCreating
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.admin_panel_settings, size: 24),
                label: Column(
                  children: [
                    Text(
                      'WhatsApp Admin',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Contact school administration',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
