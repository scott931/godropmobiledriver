import 'message_model.dart';

class Conversation {
  final int id;
  final String title;
  final String description;
  final String conversationType;
  final int studentId;
  final String studentName;
  final String? studentAvatar;
  final int vehicleId;
  final int routeId;
  final bool isModerated;
  final int? moderatorId;
  final String? moderatorName;
  final List<int> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Message? lastMessage;
  final int unreadCount;
  final bool isOnline;
  final String? parentPhone;

  const Conversation({
    required this.id,
    required this.title,
    required this.description,
    required this.conversationType,
    required this.studentId,
    required this.studentName,
    this.studentAvatar,
    required this.vehicleId,
    required this.routeId,
    required this.isModerated,
    this.moderatorId,
    this.moderatorName,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOnline = false,
    this.parentPhone,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      conversationType: json['conversation_type'] as String,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String,
      studentAvatar: json['student_avatar'] as String?,
      vehicleId: json['vehicle_id'] as int,
      routeId: json['route_id'] as int,
      isModerated: json['is_moderated'] as bool,
      moderatorId: json['moderator_id'] as int?,
      moderatorName: json['moderator_name'] as String?,
      participantIds:
          (json['participant_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      parentPhone: json['parent_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'conversation_type': conversationType,
      'student_id': studentId,
      'student_name': studentName,
      'student_avatar': studentAvatar,
      'vehicle_id': vehicleId,
      'route_id': routeId,
      'is_moderated': isModerated,
      'moderator_id': moderatorId,
      'moderator_name': moderatorName,
      'participant_ids': participantIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_online': isOnline,
      'parent_phone': parentPhone,
    };
  }

  Conversation copyWith({
    int? id,
    String? title,
    String? description,
    String? conversationType,
    int? studentId,
    String? studentName,
    String? studentAvatar,
    int? vehicleId,
    int? routeId,
    bool? isModerated,
    int? moderatorId,
    String? moderatorName,
    List<int>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Message? lastMessage,
    int? unreadCount,
    bool? isOnline,
    String? parentPhone,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      conversationType: conversationType ?? this.conversationType,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      vehicleId: vehicleId ?? this.vehicleId,
      routeId: routeId ?? this.routeId,
      isModerated: isModerated ?? this.isModerated,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorName: moderatorName ?? this.moderatorName,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      parentPhone: parentPhone ?? this.parentPhone,
    );
  }
}
