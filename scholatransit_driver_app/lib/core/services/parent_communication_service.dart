import 'api_service.dart';

class ParentCommunicationService {
  /// Create a Parent-Driver chat
  static Future<ApiResponse<Map<String, dynamic>>> createParentDriverChat({
    required int parentId,
    required int driverId,
    required int childId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/parent-driver/',
      data: {'parent_id': parentId, 'driver_id': driverId, 'child_id': childId},
    );
  }

  /// Create a Parent-Admin chat
  static Future<ApiResponse<Map<String, dynamic>>> createParentAdminChat({
    required int parentId,
    required int adminId,
    String? subject,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/parent-admin/',
      data: {'parent_id': parentId, 'admin_id': adminId, 'subject': subject},
    );
  }

  /// Get parent's conversations
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getParentConversations({int? page, int? pageSize}) async {
    return ApiService.get<List<Map<String, dynamic>>>(
      '/communication/parent/conversations/',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
      },
    );
  }

  /// Get conversation details
  static Future<ApiResponse<Map<String, dynamic>>> getConversationDetails({
    required int conversationId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/',
    );
  }

  /// Send message in conversation
  static Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    required int conversationId,
    required String content,
    String? messageType,
    String? attachment,
    int? replyTo,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/messages/',
      data: {
        'content': content,
        'message_type': messageType ?? 'text',
        if (attachment != null) 'attachment': attachment,
        if (replyTo != null) 'reply_to': replyTo,
      },
    );
  }

  /// Send voice message
  static Future<ApiResponse<Map<String, dynamic>>> sendVoiceMessage({
    required int conversationId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      content: content,
      messageType: 'voice',
      attachment: attachment,
      replyTo: replyTo,
    );
  }

  /// Send image message
  static Future<ApiResponse<Map<String, dynamic>>> sendImageMessage({
    required int conversationId,
    required String content,
    required String attachment,
    int? replyTo,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      content: content,
      messageType: 'image',
      attachment: attachment,
      replyTo: replyTo,
    );
  }

  /// Get conversation messages
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getConversationMessages({
    required int conversationId,
    int? page,
    int? pageSize,
    String? before,
  }) async {
    return ApiService.get<List<Map<String, dynamic>>>(
      '/communication/conversations/$conversationId/messages/',
      queryParameters: {
        if (page != null) 'page': page,
        if (pageSize != null) 'page_size': pageSize,
        if (before != null) 'before': before,
      },
    );
  }

  /// Mark conversation as read
  static Future<ApiResponse<Map<String, dynamic>>> markConversationAsRead({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/read/',
    );
  }

  /// Pin conversation
  static Future<ApiResponse<Map<String, dynamic>>> pinConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/pin/',
    );
  }

  /// Unpin conversation
  static Future<ApiResponse<Map<String, dynamic>>> unpinConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/unpin/',
    );
  }

  /// Mute conversation
  static Future<ApiResponse<Map<String, dynamic>>> muteConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/mute/',
    );
  }

  /// Unmute conversation
  static Future<ApiResponse<Map<String, dynamic>>> unmuteConversation({
    required int conversationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/unmute/',
    );
  }

  /// Get unread message count
  static Future<ApiResponse<Map<String, dynamic>>> getUnreadCount({
    required int parentId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/communication/parent/$parentId/unread-count/',
    );
  }

  /// Search conversations
  static Future<ApiResponse<List<Map<String, dynamic>>>> searchConversations({
    required int parentId,
    required String query,
  }) async {
    return ApiService.get<List<Map<String, dynamic>>>(
      '/communication/parent/$parentId/search/',
      queryParameters: {'q': query},
    );
  }

  /// Get driver contact information
  static Future<ApiResponse<Map<String, dynamic>>> getDriverContact({
    required int driverId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/communication/drivers/$driverId/contact/',
    );
  }

  /// Get admin contact information
  static Future<ApiResponse<Map<String, dynamic>>> getAdminContact({
    required int adminId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/communication/admins/$adminId/contact/',
    );
  }

  /// Report conversation issue
  static Future<ApiResponse<Map<String, dynamic>>> reportConversationIssue({
    required int conversationId,
    required String issueType,
    required String description,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/report/',
      data: {'issue_type': issueType, 'description': description},
    );
  }

  /// Get conversation participants
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getConversationParticipants({required int conversationId}) async {
    return ApiService.get<List<Map<String, dynamic>>>(
      '/communication/conversations/$conversationId/participants/',
    );
  }

  /// Add participant to conversation
  static Future<ApiResponse<Map<String, dynamic>>> addParticipant({
    required int conversationId,
    required int participantId,
    required String participantType,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/participants/',
      data: {
        'participant_id': participantId,
        'participant_type': participantType,
      },
    );
  }

  /// Remove participant from conversation
  static Future<ApiResponse<Map<String, dynamic>>> removeParticipant({
    required int conversationId,
    required int participantId,
  }) async {
    return ApiService.delete<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/participants/$participantId/',
    );
  }

  /// Get conversation settings
  static Future<ApiResponse<Map<String, dynamic>>> getConversationSettings({
    required int conversationId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/settings/',
    );
  }

  /// Update conversation settings
  static Future<ApiResponse<Map<String, dynamic>>> updateConversationSettings({
    required int conversationId,
    required Map<String, dynamic> settings,
  }) async {
    return ApiService.put<Map<String, dynamic>>(
      '/communication/conversations/$conversationId/settings/',
      data: settings,
    );
  }
}
