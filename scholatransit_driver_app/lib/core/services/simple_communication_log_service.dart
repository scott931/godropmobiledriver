import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/communication_log_model.dart';

class SimpleCommunicationLogService {
  static const String _logsKey = 'communication_logs';
  static List<CommunicationLog> _logs = [];

  /// Initialize the communication log service
  static Future<void> init() async {
    await _loadLogs();
  }

  /// Load logs from SharedPreferences
  static Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_logsKey) ?? [];
      _logs = logsJson
          .map((json) => CommunicationLog.fromJson(jsonDecode(json)))
          .toList();
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
    } catch (e) {
      print('Error saving logs: $e');
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
        'Communication logged: ${log.type.displayName} to ${log.phoneNumber}',
      );
    } catch (e) {
      print('Error logging communication: $e');
    }
  }

  /// Get all communication logs
  static List<CommunicationLog> getAllLogs() {
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
}
