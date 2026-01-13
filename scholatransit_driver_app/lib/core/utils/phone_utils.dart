/// Phone number normalization utility for Kenya phone numbers
/// 
/// Normalizes phone numbers to the format expected by the backend:
/// - Removes + prefix from Kenya numbers (+254... → 254...)
/// - Converts local format to international (0717127082 → 254717127082)
/// - Handles various input formats
class PhoneUtils {
  /// Normalize a phone number to the backend format
  /// 
  /// Examples:
  /// - +254717127082 → 254717127082
  /// - 0717127082 → 254717127082
  /// - 254717127082 → 254717127082
  /// 
  /// Returns the normalized phone number string
  static String normalizePhoneNumber(String phone) {
    // Remove all whitespace, dashes, parentheses, and dots
    String cleaned = phone.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    
    // Handle local format (starts with 0)
    if (cleaned.startsWith('0')) {
      return '254' + cleaned.substring(1);
    }
    
    // Handle international format with + (Kenya: +254)
    if (cleaned.startsWith('+254')) {
      return cleaned.substring(1); // Remove +
    }
    
    // Already in correct format (254...)
    if (cleaned.startsWith('254')) {
      return cleaned;
    }
    
    // Return as-is if it doesn't match any pattern
    return cleaned;
  }
}
