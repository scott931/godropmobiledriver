import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/communication_log_model.dart';

class CommunicationLogService {
  static const String _boxName = 'communication_logs';
  static Box<CommunicationLog>? _box;

  /// Initialize the communication log service
  static Future<void> init() async {
    // For now, we'll use a simple in-memory storage
    // TODO: Implement proper Hive storage with adapters
    _box = await Hive.openBox<CommunicationLog>(_boxName);
  }

  /// Get the communication logs box
  static Box<CommunicationLog> get box {
    if (_box == null) {
      throw Exception(
        'CommunicationLogService not initialized. Call init() first.',
      );
    }
    return _box!;
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
    String? driverId = 'current_driver', // You can get this from auth service
  }) async {
    try {
      final log = CommunicationLog(
        id: const Uuid().v4(),
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

      await box.add(log);
      print(
        'Communication logged: ${log.type.displayName} to ${log.phoneNumber}',
      );
    } catch (e) {
      print('Error logging communication: $e');
    }
  }

  /// Get all communication logs
  static List<CommunicationLog> getAllLogs() {
    return box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by type
  static List<CommunicationLog> getLogsByType(CommunicationType type) {
    return box.values.where((log) => log.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get logs by date range
  static List<CommunicationLog> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return box.values
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
    return box.values.where((log) => log.phoneNumber == phoneNumber).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get successful logs only
  static List<CommunicationLog> getSuccessfulLogs() {
    return box.values.where((log) => log.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get failed logs only
  static List<CommunicationLog> getFailedLogs() {
    return box.values.where((log) => !log.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get communication statistics
  static Map<String, dynamic> getStatistics() {
    final logs = box.values.toList();

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
    await box.clear();
  }

  /// Delete a specific log
  static Future<void> deleteLog(String logId) async {
    final logIndex = box.values.toList().indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      await box.deleteAt(logIndex);
    }
  }

  /// Get recent logs (last 10)
  static List<CommunicationLog> getRecentLogs({int limit = 10}) {
    final logs = getAllLogs();
    return logs.take(limit).toList();
  }

  /// Search logs by contact name or phone number
  static List<CommunicationLog> searchLogs(String query) {
    final lowercaseQuery = query.toLowerCase();
    return box.values
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
