import 'package:flutter_test/flutter_test.dart';
import 'package:go_drop/core/models/conversation_model.dart';
import 'package:go_drop/core/models/message_model.dart';

void main() {
  group('Conversation Model Tests', () {
    test('fromJson should parse chat list response correctly', () {
      final json = {
        'id': 1,
        'chat_type': 'driver_parent',
        'other_participant': {
          'id': 2,
          'name': 'Jane Smith',
          'user_type': 'parent',
          'profile_picture': 'https://example.com/media/profiles/jane.jpg',
          'is_online': false,
        },
        'latest_message_preview': 'Thank you for the update!',
        'unread_count': 3,
        'last_message_time': '02:30 PM',
        'is_pinned': false,
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, 1);
      expect(conversation.chatType, 'driver_parent');
      expect(conversation.otherParticipant.id, 2);
      expect(conversation.otherParticipant.name, 'Jane Smith');
      expect(conversation.otherParticipant.userType, 'parent');
      expect(conversation.latestMessagePreview, 'Thank you for the update!');
      expect(conversation.unreadCount, 3);
      expect(conversation.lastMessageTime, '02:30 PM');
      expect(conversation.isPinned, false);
    });

    test('fromJson should parse chat details with messages', () {
      final json = {
        'id': 1,
        'chat_type': 'driver_parent',
        'other_participant': {
          'id': 2,
          'name': 'Jane Smith',
          'user_type': 'parent',
          'profile_picture': null,
          'is_online': true,
          'last_seen': 'Active Now',
        },
        'student': {
          'id': 5,
          'student_id': 'STU-2024-001',
          'first_name': 'Emma',
          'last_name': 'Smith',
          'full_name': 'Emma Smith',
          'grade': '3',
          'status': 'active',
          'school_name': 'Greenwood Elementary',
        },
        'messages': [
          {
            'id': 1,
            'chat': 1,
            'sender': {
              'id': 1,
              'first_name': 'John',
              'last_name': 'Driver',
              'full_name': 'John Driver',
              'display_name': 'John Driver',
              'email': 'john.driver@example.com',
              'user_type': 'driver',
              'profile_picture': null,
            },
            'message_type': 'text',
            'content': 'Hello! Emma is on the bus.',
            'attachment': null,
            'reply_to': null,
            'created_at': '2025-01-25T10:15:00Z',
            'updated_at': '2025-01-25T10:15:00Z',
          },
        ],
        'created_at': '2025-01-25T10:00:00Z',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, 1);
      expect(conversation.chatType, 'driver_parent');
      expect(conversation.student, isNotNull);
      expect(conversation.student!.id, 5);
      expect(conversation.student!.fullName, 'Emma Smith');
      expect(conversation.messages, isNotNull);
      expect(conversation.messages!.length, 1);
      expect(conversation.messages![0].id, 1);
      expect(conversation.messages![0].content, 'Hello! Emma is on the bus.');
    });

    test('displayName should return student name for driver_parent chat', () {
      final json = {
        'id': 1,
        'chat_type': 'driver_parent',
        'other_participant': {
          'id': 2,
          'name': 'Jane Smith',
          'user_type': 'parent',
        },
        'student': {
          'id': 5,
          'student_id': 'STU-2024-001',
          'first_name': 'Emma',
          'last_name': 'Smith',
          'full_name': 'Emma Smith',
          'grade': '3',
          'status': 'active',
        },
      };

      final conversation = Conversation.fromJson(json);
      expect(conversation.displayName, 'Emma Smith');
    });

    test('displayName should return participant name for other chat types', () {
      final json = {
        'id': 2,
        'chat_type': 'admin_driver',
        'other_participant': {
          'id': 5,
          'name': 'Admin User',
          'user_type': 'admin',
        },
      };

      final conversation = Conversation.fromJson(json);
      expect(conversation.displayName, 'Admin User');
    });

    test('toJson should serialize conversation correctly', () {
      final json = {
        'id': 1,
        'chat_type': 'driver_parent',
        'other_participant': {
          'id': 2,
          'name': 'Jane Smith',
          'user_type': 'parent',
          'profile_picture': null,
          'is_online': false,
        },
        'unread_count': 3,
        'is_pinned': false,
      };

      final conversation = Conversation.fromJson(json);
      final serialized = conversation.toJson();

      expect(serialized['id'], 1);
      expect(serialized['chat_type'], 'driver_parent');
      expect(serialized['unread_count'], 3);
    });
  });

  group('Message Model Tests', () {
    test('fromJson should parse message correctly', () {
      final json = {
        'id': 1,
        'chat': 1,
        'sender': {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Driver',
          'full_name': 'John Driver',
          'display_name': 'John Driver',
          'email': 'john.driver@example.com',
          'user_type': 'driver',
          'profile_picture': null,
        },
        'message_type': 'text',
        'content': 'Hello! Emma is on the bus.',
        'attachment': null,
        'reply_to': null,
        'created_at': '2025-01-25T10:15:00Z',
        'updated_at': '2025-01-25T10:15:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.id, 1);
      expect(message.conversationId, 1);
      expect(message.displaySenderId, 1);
      expect(message.displaySenderName, 'John Driver');
      expect(message.content, 'Hello! Emma is on the bus.');
      expect(message.type, MessageType.text);
      expect(message.replyTo, null);
      expect(message.hasReply, false);
    });

    test('fromJson should parse message with reply', () {
      final json = {
        'id': 2,
        'chat': 1,
        'sender': {
          'id': 2,
          'first_name': 'Jane',
          'last_name': 'Smith',
          'full_name': 'Jane Smith',
          'display_name': 'Jane Smith',
          'user_type': 'parent',
        },
        'message_type': 'text',
        'content': 'Thank you!',
        'reply_to': 1,
        'reply_to_content': 'Hello! Emma is on the bus.',
        'reply_to_sender': 'John Driver',
        'created_at': '2025-01-25T10:16:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.id, 2);
      expect(message.replyTo, 1);
      expect(message.replyToContent, 'Hello! Emma is on the bus.');
      expect(message.replyToSender, 'John Driver');
      expect(message.hasReply, true);
    });

    test('fromJson should parse image message', () {
      final json = {
        'id': 3,
        'chat': 1,
        'sender': {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Driver',
          'full_name': 'John Driver',
          'display_name': 'John Driver',
          'user_type': 'driver',
        },
        'message_type': 'image',
        'content': 'See attached photo',
        'attachment': 'https://example.com/media/chat/attachments/image_123.jpg',
        'created_at': '2025-01-25T10:20:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.type, MessageType.image);
      expect(message.attachmentUrl, 'https://example.com/media/chat/attachments/image_123.jpg');
    });

    test('fromJson should parse voice message', () {
      final json = {
        'id': 4,
        'chat': 1,
        'sender': {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Driver',
          'full_name': 'John Driver',
          'display_name': 'John Driver',
          'user_type': 'driver',
        },
        'message_type': 'voice',
        'content': 'Voice message',
        'attachment': 'https://example.com/media/chat/attachments/voice_123.mp3',
        'voice_duration': 30,
        'created_at': '2025-01-25T10:25:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.type, MessageType.voice);
      expect(message.voiceUrl, 'https://example.com/media/chat/attachments/voice_123.mp3');
      expect(message.voiceDuration, 30);
    });

    test('MessageType.fromString should handle all types', () {
      expect(MessageType.fromString('text'), MessageType.text);
      expect(MessageType.fromString('voice'), MessageType.voice);
      expect(MessageType.fromString('image'), MessageType.image);
      expect(MessageType.fromString('file'), MessageType.file);
      expect(MessageType.fromString('system'), MessageType.system);
      expect(MessageType.fromString('unknown'), MessageType.text); // Default
    });

    test('toJson should serialize message correctly', () {
      final json = {
        'id': 1,
        'chat': 1,
        'sender': {
          'id': 1,
          'first_name': 'John',
          'last_name': 'Driver',
          'full_name': 'John Driver',
          'display_name': 'John Driver',
          'user_type': 'driver',
        },
        'message_type': 'text',
        'content': 'Hello!',
        'created_at': '2025-01-25T10:15:00Z',
      };

      final message = Message.fromJson(json);
      final serialized = message.toJson();

      expect(serialized['id'], 1);
      expect(serialized['chat'], 1);
      expect(serialized['content'], 'Hello!');
      expect(serialized['message_type'], 'text');
    });
  });
}

