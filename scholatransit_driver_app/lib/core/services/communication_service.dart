import 'api_service.dart';

class CommunicationService {
  /// List all chats for the authenticated user
  static Future<ApiResponse<Map<String, dynamic>>> listChats({
    int? page,
    int? pageSize,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/communication/chats/',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      },
    );
  }

  /// Create a Driver-Parent chat (student_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createDriverParentChat({
    required int studentId,
  }) async {
    final path = '/communication/driver-parent/$studentId/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Create an Admin-Driver chat (driver_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createAdminDriverChat({
    required int driverId,
  }) async {
    final path = '/communication/admin-driver/$driverId/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Create an Admin-Parent chat (parent_id in URL)
  static Future<ApiResponse<Map<String, dynamic>>> createAdminParentChat({
    required int parentId,
  }) async {
    final path = '/communication/admin-parent/$parentId/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Create a general chat (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> createGeneralChat({
    required String title,
    required List<int> participantIds,
    String? description,
  }) async {
    final path = '/communication/general/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'title': title,
        'description': description,
        'participant_ids': participantIds,
      },
    );
  }

  /// Get chat details (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> getChatDetails({
    required int chatId,
  }) async {
    final path = '/communication/chats/$chatId/';
    return ApiService.get<Map<String, dynamic>>(path);
  }

  /// Send text message
  static Future<ApiResponse<Map<String, dynamic>>> sendTextMessage({
    required int chatId,
    required String content,
  }) async {
    final path = '/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {'content': content},
    );
  }

  /// Send voice message
  static Future<ApiResponse<Map<String, dynamic>>> sendVoiceMessage({
    required int chatId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    final path = '/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'content': content,
        'attachment': attachment,
        if (replyTo != null) 'reply_to': replyTo,
      },
    );
  }

  /// Send image message
  static Future<ApiResponse<Map<String, dynamic>>> sendImageMessage({
    required int chatId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    final path = '/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'message_type': 'image',
        'content': content,
        'attachment': attachment,
        if (replyTo != null) 'reply_to': replyTo,
      },
    );
  }

  /// Reply to a message in a chat
  static Future<ApiResponse<Map<String, dynamic>>> replyToMessage({
    required int chatId,
    required int replyToMessageId,
    required String content,
    String? attachment,
  }) async {
    final path = '/communication/chats/$chatId/messages/';
    return ApiService.post<Map<String, dynamic>>(
      path,
      data: {
        'message_type': 'text',
        'content': content,
        'attachment': attachment,
        'reply_to': replyToMessageId,
      },
    );
  }

  /// Mark a chat as read (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> markChatAsRead({
    required int chatId,
  }) async {
    final path = '/communication/chats/$chatId/read/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Toggle chat pin (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> toggleChatPin({
    required int chatId,
  }) async {
    final path = '/communication/chats/$chatId/pin/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Toggle chat mute (any participant)
  static Future<ApiResponse<Map<String, dynamic>>> toggleChatMute({
    required int chatId,
  }) async {
    final path = '/communication/chats/$chatId/mute/';
    return ApiService.post<Map<String, dynamic>>(path);
  }

  /// Get unread count across chats (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> getUnreadCount() async {
    final path = '/communication/unread-count/';
    return ApiService.get<Map<String, dynamic>>(path);
  }

  /// Search chats (any authenticated user)
  static Future<ApiResponse<Map<String, dynamic>>> searchChats({
    required String query,
  }) async {
    final path = '/communication/search/';
    return ApiService.get<Map<String, dynamic>>(
      path,
      queryParameters: {'q': query},
    );
  }
}
