import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Launch WhatsApp with a specific phone number
  static Future<bool> launchWhatsApp({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty ||
          phoneNumber == '+1234567890' ||
          phoneNumber == '+1987654321') {
        print('Invalid or placeholder phone number: $phoneNumber');
        return false;
      }

      // Clean and format phone number
      final formattedPhoneNumber = _formatPhoneNumber(phoneNumber);

      if (formattedPhoneNumber.isEmpty) {
        print('Failed to format phone number: $phoneNumber');
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
          return true;
        }
      } catch (e) {
        print('Primary WhatsApp launch failed: $e');
      }

      // Try alternative method with whatsapp:// protocol
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
          return true;
        }
      } catch (e2) {
        print('Alternative WhatsApp launch also failed: $e2');
      }

      // If both methods fail, return false
      print('All WhatsApp launch methods failed');
      return false;
    } catch (e) {
      print('Error launching WhatsApp: $e');
      return false;
    }
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
  }) async {
    return launchWhatsApp(phoneNumber: phoneNumber, message: message);
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

  /// Check if phone number is valid for WhatsApp
  static bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;

    // Check if it's a placeholder number
    if (phoneNumber == '+1234567890' || phoneNumber == '+1987654321') {
      return false;
    }

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Kenyan numbers should be 12 digits (254 + 9 digits)
    if (phoneNumber.startsWith('+254') || cleanNumber.startsWith('254')) {
      return cleanNumber.length >= 12;
    }

    // Other international numbers should be at least 10 digits
    return cleanNumber.length >= 10;
  }
}
