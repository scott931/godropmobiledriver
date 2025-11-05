class Message {
  final int id;
  final int conversationId;
  final int? senderId;
  final String? senderName;
  final String? senderAvatar;
  final SenderInfo? sender; // New API structure
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? voiceUrl;
  final int? voiceDuration; // in seconds
  final String? attachmentUrl;
  final String? attachmentType;

  // Reply fields
  final int? replyTo;
  final String? replyToContent;
  final String? replyToSender;

  const Message({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.sender,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.voiceUrl,
    this.voiceDuration,
    this.attachmentUrl,
    this.attachmentType,
    this.replyTo,
    this.replyToContent,
    this.replyToSender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Validate input
    if (json.isEmpty) {
      throw ArgumentError('Cannot parse Message from empty JSON');
    }

    // Handle sender field - can be object, int, or just id/name
    SenderInfo? sender;
    int? senderIdFromSender;
    Map<String, dynamic>? senderMap;

    try {
      final senderField = json['sender'];
      if (senderField != null) {
        if (senderField is Map<String, dynamic>) {
          senderMap = senderField;
          try {
            sender = SenderInfo.fromJson(senderMap);
          } catch (e, stackTrace) {
            print('⚠️ ERROR: Failed to parse sender object: $e');
            print('Stack: $stackTrace');
            print('Sender data: $senderMap');
          }
        } else if (senderField is int) {
          senderIdFromSender = senderField;
        } else {
          print(
            '⚠️ DEBUG: sender is neither Map nor int: ${senderField.runtimeType}, value: $senderField',
          );
        }
      }
    } catch (e, stackTrace) {
      print('⚠️ ERROR: Exception parsing sender field: $e');
      print('Stack: $stackTrace');
    }

    // Extract sender info from various possible fields
    int? senderId;
    try {
      senderId =
          json['sender_id'] as int? ??
          senderIdFromSender ??
          senderMap?['id'] as int? ??
          sender?.id;
    } catch (e) {
      print('⚠️ ERROR: Failed to extract sender_id: $e');
      senderId = senderIdFromSender ?? sender?.id;
    }

    String? senderName;
    try {
      senderName =
          json['sender_name'] as String? ??
          senderMap?['display_name'] as String? ??
          senderMap?['full_name'] as String? ??
          sender?.displayName ??
          sender?.fullName;
    } catch (e) {
      print('⚠️ ERROR: Failed to extract sender_name: $e');
      senderName = sender?.displayName ?? sender?.fullName ?? 'Unknown';
    }

    String? senderAvatar;
    try {
      senderAvatar =
          json['sender_avatar'] as String? ??
          senderMap?['profile_picture'] as String? ??
          sender?.profilePicture;
    } catch (e) {
      print('⚠️ ERROR: Failed to extract sender_avatar: $e');
      senderAvatar = sender?.profilePicture;
    }

    // Parse message type
    final messageTypeStr =
        json['message_type'] as String? ?? json['type'] as String? ?? 'text';
    final messageType = MessageType.fromString(messageTypeStr);

    // Parse timestamp
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(
        json['created_at'] as String? ??
            json['timestamp'] as String? ??
            DateTime.now().toIso8601String(),
      );
    } catch (e) {
      timestamp = DateTime.now();
    }

    // Parse attachment - check multiple possible fields
    String? attachmentUrl;
    String? attachmentType;
    String? voiceUrl;

    try {
      // Determine message type early to prioritize correctly
      final messageTypeStr =
          json['message_type'] as String? ?? json['type'] as String?;
      final isVoiceMessage = messageTypeStr == 'voice';
      final isImageMessage = messageTypeStr == 'image';

      // PRIORITY 1: Check attachment field FIRST (most common in chat details response)
      // The API returns attachment URLs directly in the 'attachment' field as a string
      // Can be null, empty string, or full URL string
      if (json['attachment'] != null) {
        if (json['attachment'] is String) {
          final url = json['attachment'] as String;
          // Check for valid URL (not null, not empty, not the string "null")
          if (url.isNotEmpty &&
              url != 'null' &&
              url.toLowerCase() != 'none' &&
              (url.startsWith('http://') || url.startsWith('https://'))) {
            attachmentUrl = url;
            // If voice message, also set voiceUrl
            if (isVoiceMessage) {
              voiceUrl = url;
            }
            print('✅ Found attachment URL in attachment field: $url');
          } else if (url.isNotEmpty &&
              url != 'null' &&
              url.toLowerCase() != 'none') {
            // Relative URL - will be handled by URL construction in widgets
            attachmentUrl = url;
            if (isVoiceMessage) {
              voiceUrl = url;
            }
            print('✅ Found relative attachment URL in attachment field: $url');
          } else {
            print('⚠️ Attachment field exists but is invalid: "$url"');
          }
        } else if (json['attachment'] is Map<String, dynamic>) {
          final attachmentMap = json['attachment'] as Map<String, dynamic>;
          final url =
              attachmentMap['url'] as String? ??
              attachmentMap['file'] as String? ??
              attachmentMap['attachment'] as String?;
          if (url != null && url.isNotEmpty) {
            attachmentUrl = url;
            // If voice message, also set voiceUrl
            if (isVoiceMessage) {
              voiceUrl = url;
            }
            print('✅ Found attachment URL in attachment map: $url');
          }
          attachmentType = attachmentMap['type'] as String?;
        } else if (json['attachment'] is int) {
          // Attachment might be an ID reference - skip
          print('⚠️ DEBUG: attachment is an int (ID): ${json['attachment']}');
        } else {
          print(
            '⚠️ DEBUG: attachment is unexpected type: ${json['attachment'].runtimeType}',
          );
        }
      }

      // PRIORITY 2: Check voice_url for voice messages (only if not already found)
      if (isVoiceMessage && voiceUrl == null) {
        if (json['voice_url'] != null && json['voice_url'] is String) {
          final url = json['voice_url'] as String;
          if (url.isNotEmpty) {
            voiceUrl = url;
            attachmentUrl ??= url;
            print('✅ Found voice URL in voice_url field: $url');
          }
        }
      }

      // PRIORITY 3: Check attachment_url (fallback - some API responses use this)
      if (attachmentUrl == null &&
          json['attachment_url'] != null &&
          json['attachment_url'] is String) {
        final url = json['attachment_url'] as String;
        if (url.isNotEmpty) {
          attachmentUrl = url;
          // If voice message and no voice_url yet, use attachment_url
          if (isVoiceMessage) {
            voiceUrl = url;
          }
          print('✅ Found attachment URL in attachment_url field: $url');
        }
      }

      // If still no URL and message type suggests it should have one, log warning with full JSON
      if (attachmentUrl == null && voiceUrl == null) {
        if (isVoiceMessage || isImageMessage || messageTypeStr == 'file') {
          print('⚠️ WARNING: $messageTypeStr message has no attachment URL');
          print('   Message JSON keys: ${json.keys.toList()}');
          print(
            '   URL-related fields: ${json.keys.where((k) => k.toLowerCase().contains('attach') || k.toLowerCase().contains('url')).toList()}',
          );
          print('   Full JSON: $json');
        }
      } else {
        // Debug: log successful URL parsing
        if (isVoiceMessage) {
          print('✅ Voice message URL parsed:');
          print('   voiceUrl: $voiceUrl');
          print('   attachmentUrl: $attachmentUrl');
        } else if (isImageMessage) {
          print('✅ Image message URL parsed:');
          print('   attachmentUrl: $attachmentUrl');
        }
      }
    } catch (e) {
      print('⚠️ ERROR: Failed to parse attachment: $e');
      print('   JSON keys: ${json.keys.toList()}');
      attachmentUrl = null;
      attachmentType = null;
      voiceUrl = null;
    }

    // Parse reply fields
    final replyTo = json['reply_to'] as int?;
    final replyToContent = json['reply_to_content'] as String?;
    final replyToSender = json['reply_to_sender'] as String?;

    // Parse conversationId - handle different field names and types
    int conversationId = 0;
    try {
      if (json['chat'] != null) {
        if (json['chat'] is int) {
          conversationId = json['chat'] as int;
        } else if (json['chat'] is Map<String, dynamic>) {
          conversationId =
              (json['chat'] as Map<String, dynamic>)['id'] as int? ?? 0;
        } else {
          print(
            '⚠️ DEBUG: chat field is neither int nor Map: ${json['chat'].runtimeType}',
          );
        }
      } else {
        conversationId =
            json['conversation_id'] as int? ?? json['chat_id'] as int? ?? 0;
      }
    } catch (e) {
      print('⚠️ ERROR: Failed to parse conversationId: $e');
      conversationId =
          json['conversation_id'] as int? ?? json['chat_id'] as int? ?? 0;
    }

    // Parse content safely
    String content;
    try {
      content = json['content'] as String? ?? '';
    } catch (e) {
      print('⚠️ ERROR: Failed to parse content: $e');
      content = '';
    }

    // Parse ID safely
    int messageId;
    try {
      messageId = json['id'] as int;
    } catch (e) {
      print('⚠️ ERROR: Failed to parse message id: $e, using fallback');
      messageId = DateTime.now().millisecondsSinceEpoch;
    }

    // Parse voice duration - check multiple possible fields
    int? parsedVoiceDuration;
    try {
      // Try voice_duration first
      if (json['voice_duration'] != null) {
        if (json['voice_duration'] is int) {
          parsedVoiceDuration = json['voice_duration'] as int;
        } else if (json['voice_duration'] is String) {
          parsedVoiceDuration = int.tryParse(json['voice_duration'] as String);
        } else if (json['voice_duration'] is double) {
          parsedVoiceDuration = (json['voice_duration'] as double).round();
        }
      }
      // Try duration as fallback
      if (parsedVoiceDuration == null && json['duration'] != null) {
        if (json['duration'] is int) {
          parsedVoiceDuration = json['duration'] as int;
        } else if (json['duration'] is String) {
          parsedVoiceDuration = int.tryParse(json['duration'] as String);
        } else if (json['duration'] is double) {
          parsedVoiceDuration = (json['duration'] as double).round();
        }
      }

      // Debug logging for voice messages
      final messageTypeStr =
          json['message_type'] as String? ?? json['type'] as String?;
      if (messageTypeStr == 'voice') {
        print('📊 Parsing voice duration:');
        print(
          '   voice_duration field: ${json['voice_duration']} (type: ${json['voice_duration']?.runtimeType})',
        );
        print(
          '   duration field: ${json['duration']} (type: ${json['duration']?.runtimeType})',
        );
        print('   Parsed duration: $parsedVoiceDuration');
        if (parsedVoiceDuration == null) {
          print(
            '   ⚠️ No duration found - available fields: ${json.keys.where((k) => k.toLowerCase().contains('duration') || k.toLowerCase().contains('time')).toList()}',
          );
        }
      }
    } catch (e) {
      print('⚠️ Error parsing voice duration: $e');
      parsedVoiceDuration = null;
    }

    return Message(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      sender: sender,
      content: content,
      type: messageType,
      timestamp: timestamp,
      isRead: json['is_read'] as bool? ?? false,
      voiceUrl: voiceUrl ?? json['voice_url'] as String? ?? attachmentUrl,
      voiceDuration: parsedVoiceDuration,
      attachmentUrl:
          attachmentUrl ?? json['attachment_url'] as String? ?? voiceUrl,
      attachmentType:
          attachmentType ??
          json['attachment_type'] as String? ??
          (messageType == MessageType.image
              ? 'image'
              : messageType == MessageType.voice
              ? 'audio'
              : messageType == MessageType.file
              ? 'file'
              : null),
      replyTo: replyTo,
      replyToContent: replyToContent,
      replyToSender: replyToSender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat': conversationId,
      'conversation_id': conversationId,
      'sender_id': senderId ?? sender?.id,
      'sender_name': senderName ?? sender?.displayName ?? sender?.fullName,
      'sender_avatar': senderAvatar ?? sender?.profilePicture,
      'sender': sender?.toJson(),
      'content': content,
      'message_type': type.toString().split('.').last,
      'type': type.toString().split('.').last,
      'created_at': timestamp.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'voice_url': voiceUrl,
      'voice_duration': voiceDuration,
      'attachment': attachmentUrl,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'reply_to': replyTo,
      'reply_to_content': replyToContent,
      'reply_to_sender': replyToSender,
    };
  }

  Message copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? senderName,
    String? senderAvatar,
    SenderInfo? sender,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? voiceUrl,
    int? voiceDuration,
    String? attachmentUrl,
    String? attachmentType,
    int? replyTo,
    String? replyToContent,
    String? replyToSender,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      replyTo: replyTo ?? this.replyTo,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSender: replyToSender ?? this.replyToSender,
    );
  }

  // Helper getters
  String get displaySenderName {
    return senderName ?? sender?.displayName ?? sender?.fullName ?? 'Unknown';
  }

  String? get displayAvatar {
    return senderAvatar ?? sender?.profilePicture;
  }

  int? get displaySenderId {
    return senderId ?? sender?.id;
  }

  bool get hasReply {
    return replyTo != null && replyTo! > 0;
  }
}

class SenderInfo {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String displayName;
  final String? email;
  final String userType;
  final String? profilePicture;

  const SenderInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.displayName,
    this.email,
    required this.userType,
    this.profilePicture,
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    try {
      return SenderInfo(
        id: json['id'] as int? ?? 0,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        fullName:
            json['full_name'] as String? ??
            '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
        displayName:
            json['display_name'] as String? ??
            json['full_name'] as String? ??
            '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
        email: json['email'] as String?,
        userType: json['user_type'] as String? ?? 'unknown',
        profilePicture: json['profile_picture'] as String?,
      );
    } catch (e, stackTrace) {
      print('❌ ERROR: Failed to parse SenderInfo: $e');
      print('Stack: $stackTrace');
      print('JSON data: $json');
      // Return default sender info
      return SenderInfo(
        id: 0,
        firstName: '',
        lastName: '',
        fullName: 'Unknown',
        displayName: 'Unknown',
        userType: 'unknown',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'display_name': displayName,
      'email': email,
      'user_type': userType,
      'profile_picture': profilePicture,
    };
  }
}

enum MessageType {
  text,
  voice,
  image,
  file,
  system;

  static MessageType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'voice':
        return MessageType.voice;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  @override
  String toString() {
    return name;
  }
}
