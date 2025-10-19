import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/communication_log_model.dart';

class SimpleCommunicationLogService {
  static const String _logsKey = 'communication_logs';
  static List<CommunicationLog> _logs = [];
  static bool _isInitialized = false;

  /// Initialize the communication log service
  static Future<void> init() async {
    if (_isInitialized) return;
    await _loadLogs();
    _isInitialized = true;
  }

  /// Load logs from SharedPreferences
  static Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_logsKey) ?? [];

      // Parse logs with error handling for individual entries
      final List<CommunicationLog> loadedLogs = [];
      for (final jsonString in logsJson) {
        try {
          final json = jsonDecode(jsonString);
          final log = CommunicationLog.fromJson(json);
          loadedLogs.add(log);
        } catch (e) {
          print('Error parsing log entry: $e, skipping entry: $jsonString');
          // Continue with other entries instead of failing completely
        }
      }

      _logs = loadedLogs;
      print('Loaded ${_logs.length} communication logs from storage');
    } catch (e) {
      print('Error loading logs: $e');
      _logs = [];
    }
  }

  /// Save logs to SharedPreferences
  static Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => jsonEncode(log.toJson())).toList();
      await prefs.setStringList(_logsKey, logsJson);
      print('Saved ${_logs.length} communication logs to storage');
    } catch (e) {
      print('Error saving logs: $e');
      // Try to save individual logs if batch save fails
      await _saveLogsIndividually();
    }
  }

  /// Fallback method to save logs individually if batch save fails
  static Future<void> _saveLogsIndividually() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> logsJson = [];

      for (final log in _logs) {
        try {
          logsJson.add(jsonEncode(log.toJson()));
        } catch (e) {
          print('Error encoding individual log: $e');
        }
      }

      await prefs.setStringList(_logsKey, logsJson);
      print('Saved ${logsJson.length} communication logs individually');
    } catch (e) {
      print('Error saving logs individually: $e');
    }
  }

  /// Log a communication attempt
  static Future<void> logCommunication({
    required String phoneNumber,
    required String contactName,
    required CommunicationType type,
    required bool success,
    String? message,
    String? errorMessage,
    String? studentName,
    String? driverId = 'current_driver',
  }) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await init();
      }

      final log = CommunicationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: phoneNumber,
        contactName: contactName,
        type: type,
        timestamp: DateTime.now(),
        message: message,
        success: success,
        errorMessage: errorMessage,
        driverId: driverId ?? 'current_driver',
        studentName: studentName,
      );

      _logs.add(log);
      await _saveLogs();
      print(
        'Communication logged: ${log.type.displayName} to ${log.phoneNumber} (Success: $success)',
      );
    } catch (e) {
      print('Error logging communication: $e');
      // Try to save the log even if there's an error
      try {
        await _saveLogs();
      } catch (saveError) {
        print('Failed to save logs after error: $saveError');
      }
    }
  }

  /// Get all communication logs
  static List<CommunicationLog> getAllLogs() {
    // Ensure service is initialized
    if (!_isInitialized) {
      print('Warning: Service not initialized, returning empty logs');
      return [];
    }
    return List.from(_logs)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by type
  static List<CommunicationLog> getLogsByType(CommunicationType type) {
    return _logs.where((log) => log.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by date range
  static List<CommunicationLog> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _logs
        .where(
          (log) =>
              log.timestamp.isAfter(startDate) &&
              log.timestamp.isBefore(endDate),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by phone number
  static List<CommunicationLog> getLogsByPhoneNumber(String phoneNumber) {
    return _logs.where((log) => log.phoneNumber == phoneNumber).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get successful logs only
  static List<CommunicationLog> getSuccessfulLogs() {
    return _logs.where((log) => log.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get failed logs only
  static List<CommunicationLog> getFailedLogs() {
    return _logs.where((log) => !log.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get communication statistics
  static Map<String, dynamic> getStatistics() {
    final logs = _logs;

    final totalLogs = logs.length;
    final successfulLogs = logs.where((log) => log.success).length;
    final failedLogs = totalLogs - successfulLogs;

    final callLogs = logs
        .where((log) => log.type == CommunicationType.call)
        .length;
    final whatsappLogs = logs
        .where((log) => log.type == CommunicationType.whatsapp)
        .length;
    final smsLogs = logs
        .where((log) => log.type == CommunicationType.sms)
        .length;

    return {
      'total': totalLogs,
      'successful': successfulLogs,
      'failed': failedLogs,
      'success_rate': totalLogs > 0
          ? (successfulLogs / totalLogs * 100).toStringAsFixed(1)
          : '0.0',
      'calls': callLogs,
      'whatsapp': whatsappLogs,
      'sms': smsLogs,
    };
  }

  /// Clear all logs
  static Future<void> clearAllLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  /// Delete a specific log
  static Future<void> deleteLog(String logId) async {
    _logs.removeWhere((log) => log.id == logId);
    await _saveLogs();
  }

  /// Get recent logs (last 10)
  static List<CommunicationLog> getRecentLogs({int limit = 10}) {
    final logs = getAllLogs();
    return logs.take(limit).toList();
  }

  /// Search logs by contact name or phone number
  static List<CommunicationLog> searchLogs(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _logs
        .where(
          (log) =>
              log.contactName.toLowerCase().contains(lowercaseQuery) ||
              log.phoneNumber.contains(query) ||
              (log.studentName?.toLowerCase().contains(lowercaseQuery) ??
                  false),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Force reload logs from storage
  static Future<void> reloadLogs() async {
    await _loadLogs();
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Get current log count
  static int get logCount => _logs.length;

  /// Add test logs for debugging (remove in production)
  static Future<void> addTestLogs() async {
    if (!_isInitialized) {
      await init();
    }

    final testLogs = [
      CommunicationLog(
        id: 'test_1',
        phoneNumber: '+254712345678',
        contactName: 'Test Parent 1',
        type: CommunicationType.call,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        success: true,
        driverId: 'test_driver',
        studentName: 'John Doe',
      ),
      CommunicationLog(
        id: 'test_2',
        phoneNumber: '+254712345679',
        contactName: 'Test Parent 2',
        type: CommunicationType.whatsapp,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        success: false,
        errorMessage: 'WhatsApp not available',
        driverId: 'test_driver',
        studentName: 'Jane Smith',
      ),
    ];

    for (final log in testLogs) {
      _logs.add(log);
    }

    await _saveLogs();
    print('Added ${testLogs.length} test logs');
  }
}
