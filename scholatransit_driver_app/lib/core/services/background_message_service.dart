import 'dart:async';
import 'communication_service.dart';
import 'notification_service.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

/// Service to handle background message checking and notifications
/// This service continues to work even when the app is in the background
class BackgroundMessageService {
  static Timer? _backgroundTimer;
  static bool _isRunning = false;
  static final Map<int, int> _lastMessageIds = {}; // chatId -> lastMessageId

  /// Start background message checking
  /// This will check for new messages periodically even when app is in background
  static void startBackgroundChecking() {
    if (_isRunning) {
      print('⚠️ BackgroundMessageService: Already running');
      return;
    }

    _isRunning = true;
    print('✅ BackgroundMessageService: Starting background message checking');

    // Check immediately
    _checkForNewMessages();

    // Check every 30 seconds when app is in background
    // (More frequent when app is in foreground is handled by RealtimeUpdateService)
    _backgroundTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      _checkForNewMessages();
    });
  }

  /// Stop background message checking
  static void stopBackgroundChecking() {
    _isRunning = false;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    print('🛑 BackgroundMessageService: Stopped background checking');
  }

  /// Check for new messages and show notifications
  static Future<void> _checkForNewMessages() async {
    try {
      // Get all chats
      final chatsResponse = await CommunicationService.listChats();
      if (!chatsResponse.success || chatsResponse.data == null) {
        return;
      }

      List<dynamic> chatsData;
      if (chatsResponse.data is List) {
        chatsData = chatsResponse.data as List;
      } else if (chatsResponse.data is Map<String, dynamic>) {
        final data = chatsResponse.data as Map<String, dynamic>;
        if (data.containsKey('results')) {
          chatsData = data['results'] as List? ?? [];
        } else if (data.containsKey('data')) {
          chatsData = data['data'] as List? ?? [];
        } else {
          chatsData = [];
        }
      } else {
        chatsData = [];
      }

      // Check each chat for new messages
      for (var chatJson in chatsData) {
        if (chatJson is! Map<String, dynamic>) continue;

        try {
          final conversation = Conversation.fromJson(chatJson);
          final chatId = conversation.id;
          final unreadCount = conversation.unreadCount;

          // Skip if no unread messages
          if (unreadCount == 0) continue;

          // Get latest messages for this chat
          final messagesResponse = await CommunicationService.getChatMessages(
            chatId: chatId,
          );

          if (!messagesResponse.success || messagesResponse.data == null) {
            continue;
          }

          List<dynamic> messagesData;
          if (messagesResponse.data is List) {
            messagesData = messagesResponse.data as List;
          } else if (messagesResponse.data is Map<String, dynamic>) {
            final data = messagesResponse.data as Map<String, dynamic>;
            if (data.containsKey('results')) {
              messagesData = data['results'] as List? ?? [];
            } else if (data.containsKey('data')) {
              messagesData = data['data'] as List? ?? [];
            } else {
              messagesData = [];
            }
          } else {
            messagesData = [];
          }

          if (messagesData.isEmpty) continue;

          // Get the latest message
          final latestMessageJson = messagesData.first;
          if (latestMessageJson is! Map<String, dynamic>) continue;

          final latestMessage = Message.fromJson(latestMessageJson);
          final lastKnownMessageId = _lastMessageIds[chatId];

          // Check if this is a new message we haven't notified about
          if (lastKnownMessageId == null ||
              latestMessage.id > lastKnownMessageId) {
            // This is a new message - show notification
            final senderName = latestMessage.displaySenderName.isNotEmpty
                ? latestMessage.displaySenderName
                : 'Someone';

            String messageContent = latestMessage.content;
            if (latestMessage.type == MessageType.voice) {
              messageContent = '🎤 Voice message';
            } else if (latestMessage.type == MessageType.image) {
              messageContent = '📷 Image';
            } else if (messageContent.isEmpty) {
              messageContent = 'New message';
            }

            // Show notification
            await NotificationService.showMessageNotification(
              senderName: senderName,
              messageContent: messageContent,
              chatId: chatId,
              chatName: conversation.displayName,
            );

            // Update last known message ID
            _lastMessageIds[chatId] = latestMessage.id;
          }
        } catch (e) {
          // Silently handle errors for individual chats
          print('⚠️ BackgroundMessageService: Error checking chat: $e');
        }
      }
    } catch (e) {
      print('❌ BackgroundMessageService: Error checking for messages: $e');
    }
  }

  /// Initialize last message ID for a chat (call when chat is opened)
  static void initializeChatLastMessage(int chatId, int lastMessageId) {
    _lastMessageIds[chatId] = lastMessageId;
  }

  /// Clear tracking for a chat (call when chat is marked as read)
  static void clearChatTracking(int chatId) {
    _lastMessageIds.remove(chatId);
  }

  /// Check if service is running
  static bool get isRunning => _isRunning;
}
