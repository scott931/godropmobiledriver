class CommunicationLog {
  final String id;
  final String phoneNumber;
  final String contactName;
  final CommunicationType type;
  final DateTime timestamp;
  final String? message;
  final bool success;
  final String? errorMessage;
  final String driverId;
  final String? studentName;

  const CommunicationLog({
    required this.id,
    required this.phoneNumber,
    required this.contactName,
    required this.type,
    required this.timestamp,
    this.message,
    required this.success,
    this.errorMessage,
    required this.driverId,
    this.studentName,
  });

  factory CommunicationLog.fromJson(Map<String, dynamic> json) {
    return CommunicationLog(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      contactName: json['contact_name'] as String,
      type: CommunicationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CommunicationType.call,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String?,
      success: json['success'] as bool,
      errorMessage: json['error_message'] as String?,
      driverId: json['driver_id'] as String,
      studentName: json['student_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'success': success,
      'error_message': errorMessage,
      'driver_id': driverId,
      'student_name': studentName,
    };
  }

  CommunicationLog copyWith({
    String? id,
    String? phoneNumber,
    String? contactName,
    CommunicationType? type,
    DateTime? timestamp,
    String? message,
    bool? success,
    String? errorMessage,
    String? driverId,
    String? studentName,
  }) {
    return CommunicationLog(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      driverId: driverId ?? this.driverId,
      studentName: studentName ?? this.studentName,
    );
  }
}

enum CommunicationType { call, whatsapp, sms }

extension CommunicationTypeExtension on CommunicationType {
  String get displayName {
    switch (this) {
      case CommunicationType.call:
        return 'Phone Call';
      case CommunicationType.whatsapp:
        return 'WhatsApp';
      case CommunicationType.sms:
        return 'SMS';
    }
  }

  String get icon {
    switch (this) {
      case CommunicationType.call:
        return '📞';
      case CommunicationType.whatsapp:
        return '💬';
      case CommunicationType.sms:
        return '📱';
    }
  }
}
