import 'dart:async';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'communication_service.dart';
import 'api_service.dart';
import 'notification_service.dart';
import '../config/app_config.dart';

/// Service for real-time updates via polling
/// Polls for new messages, read status, and notifications
class RealtimeUpdateService {
  static Timer? _updateTimer;
  static bool _isPolling = false;
  static final Set<int> _activeChatIds = {};
  static final Map<int, int> _lastMessageIds = {}; // Track last message ID per chat
  static final Map<int, DateTime> _lastCheckTimes = {}; // Track last check time per chat
  static final Map<int, Map<int, bool>> _messageReadStatus = {}; // Track read status per message per chat
  static int? _currentChatId; // Currently open chat
  static final Map<int, String> _chatNames = {}; // Cache chat names for notifications
  static final Set<int> _notifiedMessageIds = {}; // Track which messages we've notified about

  // Callbacks
  static Function(List<Message>)? onNewMessages;
  static Function(int, List<Message>)? onChatMessagesUpdated;
  static Function(List<Conversation>)? onChatListUpdated;
  static Function(int)? onUnreadCountUpdated;
  static Function(Map<String, dynamic>)? onNotificationReceived;

  // Configuration
  static const Duration _pollInterval = Duration(seconds: 2); // Poll every 2 seconds

  /// Start polling for updates
  static void startPolling({
    int? chatId,
    Function(List<Message>)? onNewMessages,
    Function(int, List<Message>)? onChatMessagesUpdated,
    Function(List<Conversation>)? onChatListUpdated,
    Function(int)? onUnreadCountUpdated,
    Function(Map<String, dynamic>)? onNotificationReceived,
  }) {
    if (_isPolling) {
      print('⚠️ RealtimeUpdateService: Already polling, ignoring start request');
      // Update callbacks even if already polling (for multiple screens)
      RealtimeUpdateService.onNewMessages = onNewMessages;
      RealtimeUpdateService.onChatMessagesUpdated = onChatMessagesUpdated;
      RealtimeUpdateService.onChatListUpdated = onChatListUpdated;
      RealtimeUpdateService.onUnreadCountUpdated = onUnreadCountUpdated;
      RealtimeUpdateService.onNotificationReceived = onNotificationReceived;
      if (chatId != null) {
        _activeChatIds.add(chatId);
        _currentChatId = chatId;
      }
      return;
    }

    // Set callbacks
    RealtimeUpdateService.onNewMessages = onNewMessages;
    RealtimeUpdateService.onChatMessagesUpdated = onChatMessagesUpdated;
    RealtimeUpdateService.onChatListUpdated = onChatListUpdated;
    RealtimeUpdateService.onUnreadCountUpdated = onUnreadCountUpdated;
    RealtimeUpdateService.onNotificationReceived = onNotificationReceived;

    if (chatId != null) {
      _activeChatIds.add(chatId);
      _currentChatId = chatId;
    }

    _isPolling = true;
    print('✅ RealtimeUpdateService: Starting background polling (interval: ${_pollInterval.inSeconds}s)');

    // Start immediate check
    _performUpdate();

    // Start periodic polling (every 2 seconds) - runs silently in background
    _updateTimer = Timer.periodic(_pollInterval, (timer) {
      if (!_isPolling) {
        timer.cancel();
        return;
      }

      // Verify timer is still active
      if (!timer.isActive) {
        _isPolling = false;
        startPolling(
          chatId: _currentChatId,
          onNewMessages: onNewMessages,
          onChatMessagesUpdated: onChatMessagesUpdated,
          onChatListUpdated: onChatListUpdated,
          onUnreadCountUpdated: onUnreadCountUpdated,
          onNotificationReceived: onNotificationReceived,
        );
        return;
      }

      // Silent background update - no logging
      _performUpdate();
    });
  }

  /// Stop polling for updates
  static void stopPolling() {
    if (!_isPolling) {
      return;
    }

    _updateTimer?.cancel();
    _updateTimer = null;
    _isPolling = false;
    _activeChatIds.clear();
    _lastMessageIds.clear();
    _lastCheckTimes.clear();
    _currentChatId = null;

    print('🛑 RealtimeUpdateService: Stopped polling');
  }

  /// Add a chat to monitor
  static void addActiveChat(int chatId) {
    _activeChatIds.add(chatId);
    print('📱 RealtimeUpdateService: Added chat $chatId to monitoring');
  }

  /// Remove a chat from monitoring
  static void removeActiveChat(int chatId) {
    _activeChatIds.remove(chatId);
    _lastMessageIds.remove(chatId);
    _lastCheckTimes.remove(chatId);
    _messageReadStatus.remove(chatId);
    if (_currentChatId == chatId) {
      _currentChatId = null;
    }
    print('📱 RealtimeUpdateService: Removed chat $chatId from monitoring');
  }

  /// Set the currently open chat
  static void setCurrentChat(int? chatId) {
    final previousChatId = _currentChatId;
    _currentChatId = chatId;

    if (chatId != null) {
      _activeChatIds.add(chatId);

      // Clear notifications when opening a chat
      if (previousChatId != chatId) {
        clearChatNotifications(chatId);
      }
    }
  }

  /// Initialize last message ID for a chat (call after loading messages)
  static void initializeChatLastMessage(int chatId, int lastMessageId) {
    _lastMessageIds[chatId] = lastMessageId;
    _lastCheckTimes[chatId] = DateTime.now();
    print('📱 RealtimeUpdateService: Initialized chat $chatId with last message ID: $lastMessageId');
  }

  /// Initialize read status tracking for all messages in a chat
  static void initializeChatReadStatus(int chatId, List<Message> messages) {
    if (!_messageReadStatus.containsKey(chatId)) {
      _messageReadStatus[chatId] = {};
    }

    for (final message in messages) {
      _messageReadStatus[chatId]![message.id] = message.isRead;
    }

    print('📱 RealtimeUpdateService: Initialized read status tracking for ${messages.length} messages in chat $chatId');
  }

  /// Perform update check (runs silently in background)
  static Future<void> _performUpdate() async {
    if (!_isPolling) {
      return;
    }

    try {
      // Check for new messages in active chats
      await _checkForNewMessages();

      // Always check for chat list updates (every 2 seconds) - silent background refresh
      // This ensures unread counts and new messages are always up to date
      await _checkChatListUpdates();

      // Check for unread count updates
      await _checkUnreadCount();
    } catch (e) {
      // Silently handle errors in background refresh
      // Only critical errors should be logged
    }
  }

  /// Check for new messages in active chats
  static Future<void> _checkForNewMessages() async {
    if (_activeChatIds.isEmpty) return;

    for (final chatId in _activeChatIds.toList()) {
      try {
        final response = await CommunicationService.getChatMessages(chatId: chatId);

        if (response.success && response.data != null) {
          List<dynamic> messagesData;

          // Handle different response formats
          if (response.data is List) {
            messagesData = response.data as List;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data.containsKey('results')) {
              messagesData = data['results'] as List? ?? [];
            } else if (data.containsKey('data')) {
              messagesData = data['data'] as List? ?? [];
            } else if (data.containsKey('messages')) {
              messagesData = data['messages'] as List? ?? [];
            } else {
              messagesData = [];
            }
          } else {
            messagesData = [];
          }

          // Parse messages
          final messages = messagesData
              .where((msgJson) => msgJson is Map<String, dynamic>)
              .map((msgJson) => Message.fromJson(msgJson as Map<String, dynamic>))
              .toList();

          // Sort by timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Check for new messages
          final lastMessageId = _lastMessageIds[chatId];
          if (messages.isNotEmpty) {
            final latestMessageId = messages.last.id;

            // If this is the first check, just initialize
            if (lastMessageId == null) {
              _lastMessageIds[chatId] = latestMessageId;
              _lastCheckTimes[chatId] = DateTime.now();
              continue;
            }

            // Check if there are new messages
            if (latestMessageId > lastMessageId) {
              final newMessages = messages.where((msg) => msg.id > lastMessageId).toList();

              if (newMessages.isNotEmpty) {
                print('📨 RealtimeUpdateService: Found ${newMessages.length} new messages in chat $chatId');
                _lastMessageIds[chatId] = latestMessageId;

                // Update read status tracking for new messages
                _updateReadStatusTracking(chatId, newMessages);

                // Show notifications for new messages (only if chat is not currently open)
                _showNotificationsForNewMessages(chatId, newMessages);

                // Notify callbacks
                if (onNewMessages != null) {
                  onNewMessages!(newMessages);
                }
                if (onChatMessagesUpdated != null) {
                  onChatMessagesUpdated!(chatId, newMessages);
                }
              }
            }

            // Update read status for all messages (check for read status changes)
            _updateReadStatus(chatId, messages);
          }
        }
      } catch (e) {
        print('❌ RealtimeUpdateService: Error checking messages for chat $chatId: $e');
      }
    }
  }

  /// Update read status tracking for new messages
  static void _updateReadStatusTracking(int chatId, List<Message> messages) {
    if (!_messageReadStatus.containsKey(chatId)) {
      _messageReadStatus[chatId] = {};
    }

    for (final message in messages) {
      _messageReadStatus[chatId]![message.id] = message.isRead;
    }
  }

  /// Update read status for messages and notify if changed
  static void _updateReadStatus(int chatId, List<Message> messages) {
    // Initialize read status map if needed
    if (!_messageReadStatus.containsKey(chatId)) {
      _messageReadStatus[chatId] = {};
      // Initialize with current messages
      for (final message in messages) {
        _messageReadStatus[chatId]![message.id] = message.isRead;
      }
      return;
    }

    final readStatusMap = _messageReadStatus[chatId]!;
    final messagesWithChangedStatus = <Message>[];

    // Check for read status changes
    for (final message in messages) {
      final previousReadStatus = readStatusMap[message.id];
      final currentReadStatus = message.isRead;

      // If read status changed (from unread to read)
      if (previousReadStatus != null &&
          previousReadStatus != currentReadStatus &&
          currentReadStatus == true) {
        print('📖 RealtimeUpdateService: Message ${message.id} in chat $chatId marked as read');
        messagesWithChangedStatus.add(message);
      }

      // Update tracking
      readStatusMap[message.id] = currentReadStatus;
    }

    // Notify if any read status changed
    if (messagesWithChangedStatus.isNotEmpty && onChatMessagesUpdated != null) {
      print('📖 RealtimeUpdateService: Notifying ${messagesWithChangedStatus.length} messages with read status updates');
      onChatMessagesUpdated!(chatId, messagesWithChangedStatus);
    }
  }

  /// Check for chat list updates (runs silently in background)
  static Future<void> _checkChatListUpdates() async {
    try {
      // Silent background refresh - no verbose logging
      final response = await CommunicationService.listChats();

      if (response.success && response.data != null) {
        List<dynamic> chatsData;

        if (response.data is List) {
          chatsData = response.data as List;
        } else if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
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

        final chatsList = chatsData
            .where((chatJson) => chatJson is Map<String, dynamic>)
            .map((chatJson) => Conversation.fromJson(chatJson as Map<String, dynamic>))
            .toList();

        // Sort chats: pinned first, then by last message time
        chatsList.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.id.compareTo(a.id);
        });

        // Always update chat list if callback is set (silent background update)
        if (onChatListUpdated != null) {
          onChatListUpdated!(chatsList);
        }
      }
      // Silently ignore errors in background refresh
    } catch (e) {
      // Silently ignore errors - don't spam logs for background refreshes
      // Only log if it's a critical issue
    }
  }

  /// Check for unread count updates
  static Future<void> _checkUnreadCount() async {
    try {
      final response = await CommunicationService.getUnreadCount();

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final unreadCount = data['unread_count'] as int? ?? 0;

        if (onUnreadCountUpdated != null) {
          onUnreadCountUpdated!(unreadCount);
        }
      }
    } catch (e) {
      // Silently fail - unread count is not critical
    }
  }

  /// Check notifications endpoint
  static Future<void> checkNotifications() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.notificationsEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final notifications = data['results'] as List? ?? [];

        // Check for new unread notifications
        final unreadNotifications = notifications
            .where((n) => n is Map<String, dynamic> && n['isRead'] == false)
            .toList();

        if (unreadNotifications.isNotEmpty && onNotificationReceived != null) {
          for (final notification in unreadNotifications) {
            if (notification is Map<String, dynamic>) {
              onNotificationReceived!(notification);
            }
          }
        }
      }
    } catch (e) {
      print('❌ RealtimeUpdateService: Error checking notifications: $e');
    }
  }

  /// Show notifications for new messages
  static Future<void> _showNotificationsForNewMessages(int chatId, List<Message> newMessages) async {
    // Don't show notifications if this chat is currently open
    if (_currentChatId == chatId) {
      print('📱 Chat $chatId is currently open, skipping notifications');
      return;
    }

    // Get the latest message to notify about
    if (newMessages.isEmpty) return;

    final latestMessage = newMessages.last;

    // Skip if we've already notified about this message
    if (_notifiedMessageIds.contains(latestMessage.id)) {
      return;
    }

    try {
      // Get chat name from cache or fetch it
      String? chatName = _chatNames[chatId];
      if (chatName == null) {
        // Try to get chat name from conversation details
        try {
          final chatResponse = await CommunicationService.getChatDetails(chatId: chatId);
          if (chatResponse.success && chatResponse.data != null) {
            Map<String, dynamic> chatData;
            if (chatResponse.data is Map<String, dynamic>) {
              chatData = chatResponse.data as Map<String, dynamic>;
              if (chatData.containsKey('data')) {
                chatData = chatData['data'] as Map<String, dynamic>;
              }
            } else {
              chatData = {'id': chatId};
            }

            final conversation = Conversation.fromJson(chatData);
            chatName = conversation.displayName;
            _chatNames[chatId] = chatName;
          }
        } catch (e) {
          print('⚠️ Could not fetch chat name for notification: $e');
        }
      }

      // Get sender name
      final senderName = latestMessage.displaySenderName.isNotEmpty
          ? latestMessage.displaySenderName
          : 'Someone';

      // Get message content based on type
      String messageContent = latestMessage.content;
      if (latestMessage.type == MessageType.voice) {
        messageContent = '🎤 Voice message';
      } else if (latestMessage.type == MessageType.image) {
        messageContent = '📷 Image';
      } else if (latestMessage.content.isEmpty) {
        messageContent = 'New message';
      }

      // Show notification
      await NotificationService.showMessageNotification(
        senderName: senderName,
        messageContent: messageContent,
        chatId: chatId,
        chatName: chatName,
      );

      // Mark as notified
      _notifiedMessageIds.add(latestMessage.id);

      // Keep only last 100 notified message IDs to prevent memory issues
      if (_notifiedMessageIds.length > 100) {
        final oldestIds = _notifiedMessageIds.take(_notifiedMessageIds.length - 100).toList();
        for (final id in oldestIds) {
          _notifiedMessageIds.remove(id);
        }
      }

      print('🔔 Notification shown for message ${latestMessage.id} from $senderName in chat $chatId');
    } catch (e) {
      print('❌ Error showing notification for new message: $e');
    }
  }

  /// Clear notifications for a chat (when user opens it)
  static void clearChatNotifications(int chatId) {
    // Clear notification for this chat
    NotificationService.cancelNotification(chatId);
    print('📱 Cleared notifications for chat $chatId');
  }

  /// Force an immediate update check
  static Future<void> forceUpdate() async {
    await _performUpdate();
  }

  /// Update unread count for a specific chat locally (optimistic update)
  static void updateChatUnreadCount(int chatId, int unreadCount) {
    // This will be handled by the next chat list update
    // But we can trigger an immediate update
    forceUpdate();
  }
}

