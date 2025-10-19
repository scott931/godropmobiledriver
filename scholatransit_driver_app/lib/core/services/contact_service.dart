import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  static bool _isInitialized = false;

  /// Initialize the contact service and request permissions
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check current permission status first
      final currentStatus = await Permission.contacts.status;
      print('Current contact permission status: $currentStatus');

      if (currentStatus.isGranted) {
        _isInitialized = true;
        return true;
      }

      // Request contact permission if not granted
      final status = await Permission.contacts.request();
      print('Contact permission request result: $status');

      if (status.isGranted) {
        _isInitialized = true;
        return true;
      } else if (status.isPermanentlyDenied) {
        print(
          'Contact permission permanently denied. User needs to enable it in settings.',
        );
        return false;
      } else {
        print('Contact permission denied by user');
        return false;
      }
    } catch (e) {
      print('Error initializing contact service: $e');
      return false;
    }
  }

  /// Check if contact permission is granted
  static Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  /// Request contact permission
  static Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.contacts.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings for permission management
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Get all contacts from device
  static Future<List<Contact>> getAllContacts() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('Contact service not initialized');
        return [];
      }
    }

    try {
      // Check permission again before fetching
      final permissionGranted = await hasPermission();
      if (!permissionGranted) {
        print('No contact permission granted');
        return [];
      }

      final contacts = await FlutterContacts.getContacts();
      print('Successfully retrieved ${contacts.length} contacts from device');
      return contacts;
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }

  /// Search contacts by name or phone number
  static Future<List<Contact>> searchContacts(String query) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return [];
    }

    try {
      final allContacts = await getAllContacts();
      if (query.isEmpty) return allContacts;

      final lowercaseQuery = query.toLowerCase();
      return allContacts.where((contact) {
        // Search in display name
        if (contact.displayName.toLowerCase().contains(lowercaseQuery)) {
          return true;
        }

        // Search in phone numbers
        for (final phone in contact.phones) {
          if (phone.number.toLowerCase().contains(lowercaseQuery)) {
            return true;
          }
        }

        // Search in given name and family name
        if (contact.name.first.toLowerCase().contains(lowercaseQuery)) {
          return true;
        }
        if (contact.name.last.toLowerCase().contains(lowercaseQuery)) {
          return true;
        }

        return false;
      }).toList();
    } catch (e) {
      print('Error searching contacts: $e');
      return [];
    }
  }

  /// Get contacts with phone numbers only
  static Future<List<Contact>> getContactsWithPhones() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        print('Contact service not initialized');
        return [];
      }
    }

    try {
      final allContacts = await getAllContacts();
      print('Total contacts found: ${allContacts.length}');

      final contactsWithPhones = allContacts.where((contact) {
        final hasPhones = contact.phones.isNotEmpty;
        if (hasPhones) {
          print(
            'Contact: ${contact.displayName} has ${contact.phones.length} phone(s)',
          );
          for (final phone in contact.phones) {
            print('  Phone: ${phone.number} (${phone.label})');
          }
        }
        return hasPhones;
      }).toList();

      print('Contacts with phones: ${contactsWithPhones.length}');
      return contactsWithPhones;
    } catch (e) {
      print('Error getting contacts with phones: $e');
      return [];
    }
  }

  /// Get the primary phone number for a contact
  static String? getPrimaryPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) return null;

    // Try to find a mobile number first
    for (final phone in contact.phones) {
      if (phone.label.toString().toLowerCase().contains('mobile')) {
        return phone.number;
      }
    }

    // If no mobile number, return the first phone number
    return contact.phones.first.number;
  }

  /// Format phone number for display
  static String formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null) return '';

    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If it starts with 0, replace with +254 (Kenya)
    if (cleaned.startsWith('0') && cleaned.length > 1) {
      cleaned = '+254${cleaned.substring(1)}';
    }

    // If it doesn't start with + and is 9 digits, add +254
    if (!cleaned.startsWith('+') && cleaned.length == 9) {
      cleaned = '+254$cleaned';
    }

    return cleaned;
  }

  /// Get contact display name
  static String getContactDisplayName(Contact contact) {
    if (contact.displayName.isNotEmpty) {
      return contact.displayName;
    }

    final givenName = contact.name.first;
    final familyName = contact.name.last;

    if (givenName.isNotEmpty && familyName.isNotEmpty) {
      return '$givenName $familyName';
    } else if (givenName.isNotEmpty) {
      return givenName;
    } else if (familyName.isNotEmpty) {
      return familyName;
    }

    return 'Unknown Contact';
  }

  /// Check if contact has valid phone number
  static bool hasValidPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) return false;

    for (final phone in contact.phones) {
      final phoneNumber = phone.number;
      if (phoneNumber.isNotEmpty) {
        // Basic validation - should have at least 9 digits
        final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        if (digits.length >= 9) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get diagnostic information about contacts
  static Future<Map<String, dynamic>> getContactDiagnostics() async {
    try {
      final permissionGranted = await hasPermission();
      final allContacts = await getAllContacts();
      final contactsWithPhones = await getContactsWithPhones();

      return {
        'hasPermission': permissionGranted,
        'totalContacts': allContacts.length,
        'contactsWithPhones': contactsWithPhones.length,
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hasPermission': false,
        'totalContacts': 0,
        'contactsWithPhones': 0,
        'isInitialized': _isInitialized,
      };
    }
  }

  /// Create a demo contact for testing (only for development)
  static Future<Contact> createDemoContact() async {
    final contact = Contact();
    contact.name.first = 'Demo';
    contact.name.last = 'Parent';
    contact.phones.add(Phone('+254712345678', label: PhoneLabel.mobile));
    return contact;
  }
}
