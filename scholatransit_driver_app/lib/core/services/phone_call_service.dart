import 'package:url_launcher/url_launcher.dart';
import '../services/simple_communication_log_service.dart';
import '../models/communication_log_model.dart';

class PhoneCallService {
  /// Make a phone call to the specified number
  static Future<bool> makePhoneCall({
    required String phoneNumber,
    String? contactName,
    String? studentName,
  }) async {
    bool success = false;
    String? errorMessage;

    try {
      // Validate phone number
      if (phoneNumber.isEmpty) {
        print('Phone number is empty');
        errorMessage = 'Phone number is empty';
        return false;
      }

      // Clean and format phone number for calling
      final formattedPhoneNumber = _formatPhoneNumberForCall(phoneNumber);

      if (formattedPhoneNumber.isEmpty) {
        print('Failed to format phone number: $phoneNumber');
        errorMessage = 'Failed to format phone number';
        return false;
      }

      final callUrl = 'tel:$formattedPhoneNumber';
      print('Making phone call to: $callUrl');
      final uri = Uri.parse(callUrl);

      if (await canLaunchUrl(uri)) {
        success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Cannot launch phone call URL');
        errorMessage = 'Cannot launch phone call URL';
        success = false;
      }
    } catch (e) {
      print('Error making phone call: $e');
      errorMessage = e.toString();
      success = false;
    } finally {
      // Log the communication attempt
      await SimpleCommunicationLogService.logCommunication(
        phoneNumber: phoneNumber,
        contactName: contactName ?? 'Unknown Contact',
        type: CommunicationType.call,
        success: success,
        errorMessage: errorMessage,
        studentName: studentName,
      );
    }

    return success;
  }

  /// Format phone number for making calls
  static String _formatPhoneNumberForCall(String phoneNumber) {
    // Remove all non-numeric characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If empty or too short, return empty
    if (cleanNumber.isEmpty || cleanNumber.length < 10) {
      return '';
    }

    // For Kenyan numbers, ensure proper formatting
    if (phoneNumber.startsWith('+254')) {
      return cleanNumber; // Already has country code
    }

    // If it starts with 254 (without +), add +
    if (cleanNumber.startsWith('254') && cleanNumber.length >= 12) {
      return '+$cleanNumber';
    }

    // If it's a 10-digit number starting with 0, convert to +254
    if (cleanNumber.length == 10 && cleanNumber.startsWith('0')) {
      return '+254${cleanNumber.substring(1)}';
    }

    // If it's a 9-digit number, assume it needs +254 prefix
    if (cleanNumber.length == 9 && !cleanNumber.startsWith('0')) {
      return '+254$cleanNumber';
    }

    // If it's already 12+ digits, use as is
    if (cleanNumber.length >= 12) {
      return cleanNumber;
    }

    return cleanNumber;
  }

  /// Check if phone calling is available on the device
  static Future<bool> isPhoneCallAvailable() async {
    try {
      // Try to check if phone calls can be made
      final testUri = Uri.parse('tel:1234567890');
      return await canLaunchUrl(testUri);
    } catch (e) {
      print('Error checking phone call availability: $e');
      // Assume it's available and let the launch method handle errors
      return true;
    }
  }

  /// Get default driver phone number for calling
  static String getDefaultDriverPhone() {
    return '+254717127082';
  }

  /// Get default admin phone number for calling
  static String getDefaultAdminPhone() {
    return '+254703149045';
  }

  /// Validate if a phone number is suitable for calling
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;

    // Remove all non-numeric characters except +
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it's a placeholder number
    if (cleanNumber == '1234567890' ||
        cleanNumber == '1987654321' ||
        cleanNumber == '+1234567890' ||
        cleanNumber == '+1987654321') {
      return false;
    }

    // Check minimum length (at least 10 digits)
    if (cleanNumber.length < 10) return false;

    // For Kenyan numbers, check specific length
    if (cleanNumber.startsWith('+254') || cleanNumber.startsWith('254')) {
      return cleanNumber.length >= 13; // +254XXXXXXXXX
    }

    return true;
  }
}
