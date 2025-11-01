import 'message_model.dart';

class OtherParticipant {
  final int id;
  final String name;
  final String userType;
  final String? profilePicture;
  final bool isOnline;
  final String? lastSeen;

  const OtherParticipant({
    required this.id,
    required this.name,
    required this.userType,
    this.profilePicture,
    this.isOnline = false,
    this.lastSeen,
  });

  factory OtherParticipant.fromJson(Map<String, dynamic> json) {
    try {
      return OtherParticipant(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ??
              (json['full_name'] as String? ??
               (json['first_name'] != null && json['last_name'] != null
                  ? '${json['first_name']} ${json['last_name']}'
                  : 'Unknown')),
        userType: json['user_type'] as String? ?? 'unknown',
        profilePicture: json['profile_picture'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
        lastSeen: json['last_seen'] as String?,
      );
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to parse OtherParticipant: $e');
      print('Stack: $stackTrace');
      print('JSON data: $json');
      // Return default participant
      return OtherParticipant(
        id: 0,
        name: 'Unknown',
        userType: 'unknown',
        isOnline: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_type': userType,
      'profile_picture': profilePicture,
      'is_online': isOnline,
      'last_seen': lastSeen,
    };
  }
}

class StudentInfo {
  final int id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String grade;
  final String status;
  final String? schoolName;

  const StudentInfo({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.grade,
    required this.status,
    this.schoolName,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    try {
      return StudentInfo(
        id: json['id'] as int? ?? 0,
        studentId: json['student_id'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        fullName: json['full_name'] as String? ??
                  (json['first_name'] != null && json['last_name'] != null
                    ? '${json['first_name']} ${json['last_name']}'
                    : ''),
        grade: json['grade'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        schoolName: json['school_name'] as String?,
      );
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to parse StudentInfo: $e');
      print('Stack: $stackTrace');
      print('JSON data: $json');
      // Return default student info
      return StudentInfo(
        id: 0,
        studentId: '',
        firstName: '',
        lastName: '',
        fullName: 'Unknown Student',
        grade: '',
        status: 'active',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'grade': grade,
      'status': status,
      'school_name': schoolName,
    };
  }
}

class Conversation {
  final int id;
  final String chatType;
  final OtherParticipant otherParticipant;

  // Chat list fields
  final String? latestMessagePreview;
  final int unreadCount;
  final String? lastMessageTime;
  final bool isPinned;

  // Detailed chat fields
  final StudentInfo? student;
  final List<Message>? messages;
  final DateTime? createdAt;

  // Legacy fields for backward compatibility
  final String? title;
  final String? description;
  final String? conversationType;
  final int? studentId;
  final String? studentName;
  final String? studentAvatar;
  final int? vehicleId;
  final int? routeId;
  final bool? isModerated;
  final int? moderatorId;
  final String? moderatorName;
  final List<int>? participantIds;
  final DateTime? updatedAt;
  final bool isActive;
  final Message? lastMessage;
  final bool isOnline;
  final String? parentPhone;

  const Conversation({
    required this.id,
    required this.chatType,
    required this.otherParticipant,
    this.latestMessagePreview,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.isPinned = false,
    this.student,
    this.messages,
    this.createdAt,
    // Legacy fields
    this.title,
    this.description,
    this.conversationType,
    this.studentId,
    this.studentName,
    this.studentAvatar,
    this.vehicleId,
    this.routeId,
    this.isModerated,
    this.moderatorId,
    this.moderatorName,
    this.participantIds,
    this.updatedAt,
    this.isActive = true,
    this.lastMessage,
    this.isOnline = false,
    this.parentPhone,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Parse other_participant
    OtherParticipant otherParticipant;
    if (json['other_participant'] != null) {
      if (json['other_participant'] is Map<String, dynamic>) {
        try {
          otherParticipant = OtherParticipant.fromJson(json['other_participant'] as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ ERROR: Failed to parse other_participant: $e');
          // Fallback to simple participant
          otherParticipant = OtherParticipant(
            id: json['other_user_id'] as int? ?? 0,
            name: json['other_user_name'] as String? ?? 'Unknown',
            userType: json['other_user_type'] as String? ?? 'unknown',
            profilePicture: json['other_user_avatar'] as String?,
            isOnline: json['is_online'] as bool? ?? false,
          );
        }
      } else {
        // other_participant is not a Map, use fallback
        print('⚠️ DEBUG: other_participant is not a Map: ${json['other_participant'].runtimeType}');
        otherParticipant = OtherParticipant(
          id: json['other_user_id'] as int? ?? (json['other_participant'] is int ? json['other_participant'] as int : 0),
          name: json['other_user_name'] as String? ?? 'Unknown',
          userType: json['other_user_type'] as String? ?? 'unknown',
          profilePicture: json['other_user_avatar'] as String?,
          isOnline: json['is_online'] as bool? ?? false,
        );
      }
    } else {
      // No other_participant field, use fallback
      otherParticipant = OtherParticipant(
        id: json['other_user_id'] as int? ?? 0,
        name: json['other_user_name'] as String? ?? 'Unknown',
        userType: json['other_user_type'] as String? ?? 'unknown',
        profilePicture: json['other_user_avatar'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
      );
    }

    // Parse student if available
    StudentInfo? student;
    if (json['student'] != null) {
      if (json['student'] is Map<String, dynamic>) {
        try {
          student = StudentInfo.fromJson(json['student'] as Map<String, dynamic>);
        } catch (e) {
          print('⚠️ ERROR: Failed to parse student: $e');
          student = null;
        }
      } else {
        print('⚠️ DEBUG: student is not a Map: ${json['student'].runtimeType}');
        student = null;
      }
    }

    // Parse messages if available
    List<Message>? messages;
    if (json['messages'] != null) {
      final messagesList = json['messages'];

      // Handle different message array formats
      if (messagesList is List) {
        messages = messagesList
            .where((m) {
              // Filter out non-Map items (like integers or nulls)
              if (m == null) return false;
              if (m is Map<String, dynamic>) return true;
              // Log what we're filtering out
              print('⚠️ DEBUG: Filtering out non-Map message item: ${m.runtimeType} - $m');
              return false;
            })
            .map((m) {
              try {
                if (m is! Map<String, dynamic>) {
                  print('⚠️ DEBUG: Attempting to parse non-Map as Message: ${m.runtimeType}');
                  return null;
                }
                // At this point, m is guaranteed to be Map<String, dynamic> by the type check
                final messageMap = m;
                // Validate critical fields before parsing
                if (!messageMap.containsKey('id') || messageMap['id'] is! int) {
                  print('⚠️ DEBUG: Message missing or invalid id field');
                  return null;
                }
                return Message.fromJson(messageMap);
              } catch (e, stackTrace) {
                // Skip invalid message items
                print('❌ ERROR: Skipping invalid message item: $e');
                print('Stack trace: $stackTrace');
                print('Message data type: ${m.runtimeType}');
                print('Message data: $m');
                return null;
              }
            })
            .whereType<Message>() // Remove nulls from failed parsing
            .toList();
      } else if (messagesList is Map<String, dynamic>) {
        // If messages is a single object, wrap it in a list
        try {
          messages = [Message.fromJson(messagesList)];
        } catch (e) {
          print('⚠️ ERROR: Failed to parse single message object: $e');
          messages = [];
        }
      } else {
        print('⚠️ DEBUG: Messages field is not a List or Map: ${messagesList.runtimeType}');
        messages = [];
      }
    }

    // Parse last message if available
    Message? lastMessage;
    if (json['latest_message'] != null && json['latest_message'] is Map<String, dynamic>) {
      lastMessage = Message.fromJson(json['latest_message'] as Map<String, dynamic>);
    }

    return Conversation(
      id: json['id'] as int,
      chatType: json['chat_type'] as String? ?? json['conversation_type'] as String? ?? 'unknown',
      otherParticipant: otherParticipant,
      latestMessagePreview: json['latest_message_preview'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessageTime: json['last_message_time'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      student: student,
      messages: messages,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      // Legacy fields
      title: json['title'] as String?,
      description: json['description'] as String?,
      conversationType: json['chat_type'] as String? ?? json['conversation_type'] as String?,
      studentId: student?.id ?? json['student_id'] as int?,
      studentName: student?.fullName ?? json['student_name'] as String?,
      studentAvatar: json['student_avatar'] as String?,
      vehicleId: json['vehicle_id'] as int?,
      routeId: json['route_id'] as int?,
      isModerated: json['is_moderated'] as bool?,
      moderatorId: json['moderator_id'] as int?,
      moderatorName: json['moderator_name'] as String?,
      participantIds: (json['participant_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      lastMessage: lastMessage,
      isOnline: otherParticipant.isOnline,
      parentPhone: json['parent_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_type': chatType,
      'other_participant': otherParticipant.toJson(),
      'latest_message_preview': latestMessagePreview,
      'unread_count': unreadCount,
      'last_message_time': lastMessageTime,
      'is_pinned': isPinned,
      'student': student?.toJson(),
      'messages': messages?.map((m) => m.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      // Legacy fields
      'title': title,
      'description': description,
      'conversation_type': conversationType ?? chatType,
      'student_id': studentId ?? student?.id,
      'student_name': studentName ?? student?.fullName,
      'student_avatar': studentAvatar,
      'vehicle_id': vehicleId,
      'route_id': routeId,
      'is_moderated': isModerated,
      'moderator_id': moderatorId,
      'moderator_name': moderatorName,
      'participant_ids': participantIds,
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'latest_message': lastMessage?.toJson(),
      'is_online': isOnline,
      'parent_phone': parentPhone,
    };
  }

  Conversation copyWith({
    int? id,
    String? chatType,
    OtherParticipant? otherParticipant,
    String? latestMessagePreview,
    int? unreadCount,
    String? lastMessageTime,
    bool? isPinned,
    StudentInfo? student,
    List<Message>? messages,
    DateTime? createdAt,
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
    DateTime? updatedAt,
    bool? isActive,
    Message? lastMessage,
    bool? isOnline,
    String? parentPhone,
  }) {
    return Conversation(
      id: id ?? this.id,
      chatType: chatType ?? this.chatType,
      otherParticipant: otherParticipant ?? this.otherParticipant,
      latestMessagePreview: latestMessagePreview ?? this.latestMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isPinned: isPinned ?? this.isPinned,
      student: student ?? this.student,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lastMessage: lastMessage ?? this.lastMessage,
      isOnline: isOnline ?? this.isOnline,
      parentPhone: parentPhone ?? this.parentPhone,
    );
  }

  // Helper getters for backward compatibility
  String get displayName {
    if (student != null && chatType == 'driver_parent') {
      return student!.fullName;
    }
    return otherParticipant.name;
  }

  String get displayAvatar {
    if (student != null && studentAvatar != null) {
      return studentAvatar!;
    }
    return otherParticipant.profilePicture ?? '';
  }
}
