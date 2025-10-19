import 'package:url_launcher/url_launcher.dart';
import '../services/simple_communication_log_service.dart';
import '../models/communication_log_model.dart';

class WhatsAppService {
  /// Launch WhatsApp with a specific phone number
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    String? message,
    String? contactName,
    String? studentName,
  }) async {
    bool success = false;
    String? errorMessage;

    try {
      // Validate phone number
      if (phoneNumber.isEmpty ||
          phoneNumber == '+1234567890' ||
          phoneNumber == '+1987654321') {
        print('Invalid or placeholder phone number: $phoneNumber');
        errorMessage = 'Invalid or placeholder phone number';
        return false;
      }

      // Clean and format phone number
      final formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

      if (formattedPhoneNumber.isEmpty) {
        print('Failed to format phone number: $phoneNumber');
        errorMessage = 'Failed to format phone number';
        return false;
      }

      final encodedMessage = message != null
          ? Uri.encodeComponent(message)
          : '';
      final whatsappUrl =
          'https://wa.me/$formattedPhoneNumber${encodedMessage.isNotEmpty ? '?text=$encodedMessage' : ''}';

      print('Launching WhatsApp with URL: $whatsappUrl');
      final uri = Uri.parse(whatsappUrl);

      // Try to launch WhatsApp directly
      try {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (result) {
          print('WhatsApp launched successfully');
          success = true;
        }
      } catch (e) {
        print('Primary WhatsApp launch failed: $e');
        errorMessage = 'Primary WhatsApp launch failed: $e';
      }

      // Try alternative method with whatsapp:// protocol
      if (!success) {
        try {
          final alternativeUrl =
              'whatsapp://send?phone=$formattedPhoneNumber${encodedMessage.isNotEmpty ? '&text=$encodedMessage' : ''}';
          final altUri = Uri.parse(alternativeUrl);
          final result = await launchUrl(
            altUri,
            mode: LaunchMode.externalApplication,
          );
          if (result) {
            print('WhatsApp launched successfully with alternative method');
            success = true;
          }
        } catch (e2) {
          print('Alternative WhatsApp launch also failed: $e2');
          errorMessage = 'Alternative WhatsApp launch also failed: $e2';
        }
      }

      // If both methods fail, return false
      if (!success) {
        print('All WhatsApp launch methods failed');
        errorMessage = 'All WhatsApp launch methods failed';
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      errorMessage = e.toString();
      success = false;
    } finally {
      // Log the communication attempt
      await SimpleCommunicationLogService.logCommunication(
        phoneNumber: phoneNumber,
        contactName: contactName ?? 'Unknown Contact',
        type: CommunicationType.whatsapp,
        success: success,
        message: message,
        errorMessage: errorMessage,
        studentName: studentName,
      );
    }

    return success;
  }

  /// Format phone number for WhatsApp
  static String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If empty or too short, return empty
    if (cleanNumber.isEmpty || cleanNumber.length < 10) {
      return '';
    }

    // For Kenyan numbers (+254), ensure proper formatting
    if (phoneNumber.startsWith('+254')) {
      return cleanNumber; // Already has country code
    }

    // If it starts with 254 (without +), add it
    if (cleanNumber.startsWith('254') && cleanNumber.length >= 12) {
      return cleanNumber;
    }

    // If it's a 10-digit number, assume it needs country code
    if (cleanNumber.length == 10) {
      // Check if it looks like a Kenyan number (starts with 7)
      if (cleanNumber.startsWith('7')) {
        return '254$cleanNumber'; // Add Kenyan country code
      }
      return '1$cleanNumber'; // Default to US
    }

    // If it's already 12+ digits, use as is
    if (cleanNumber.length >= 12) {
      return cleanNumber;
    }

    return cleanNumber;
  }

  /// Launch WhatsApp with a pre-filled message
  static Future<bool> launchWhatsAppWithMessage({
    required String phoneNumber,
    required String message,
    String? contactName,
    String? studentName,
  }) async {
    return launchWhatsApp(
      phoneNumber: phoneNumber,
      message: message,
      contactName: contactName,
      studentName: studentName,
    );
  }

  /// Check if WhatsApp is available on the device
  static Future<bool> isWhatsAppAvailable() async {
    try {
      // Try multiple methods to check WhatsApp availability
      final testUri1 = Uri.parse('whatsapp://send?phone=1234567890');
      final testUri2 = Uri.parse('https://wa.me/1234567890');

      // Try both methods
      final canLaunch1 = await canLaunchUrl(testUri1);
      final canLaunch2 = await canLaunchUrl(testUri2);

      // Return true if either method works
      return canLaunch1 || canLaunch2;
    } catch (e) {
      print('Error checking WhatsApp availability: $e');
      // Assume it's available and let the launch method handle errors
      return true;
    }
  }

  /// Get default driver phone number (you can modify this based on your data)
  static String getDefaultDriverPhone() {
    // Real driver phone number
    return '+254717127082';
  }

  /// Get default admin phone number
  static String getDefaultAdminPhone() {
    // Real admin phone number
    return '+254703149045';
  }

  /// Get default parent phone number
  static String getDefaultParentPhone() {
    // Replace with actual parent phone number
    return '+1234567890'; // Replace with real parent phone
  }

  /// Validate if a phone number is suitable for WhatsApp
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;

    // Check if it's a placeholder number
    if (phoneNumber == '+1234567890' ||
        phoneNumber == '+1987654321' ||
        phoneNumber == '1234567890' ||
        phoneNumber == '1987654321') {
      return false;
    }

    // Check minimum length (at least 10 digits)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length < 10) return false;

    // For Kenyan numbers, check specific length
    if (phoneNumber.startsWith('+254') || phoneNumber.startsWith('254')) {
      return cleanNumber.length >= 12; // 254XXXXXXXXX
    }

    return true;
  }
}
