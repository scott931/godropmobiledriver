import '../config/app_config.dart';
import 'api_service.dart';

class CommunicationService {
  /// Create a new conversation (Admins/Primary System)
  ///
  /// Required JSON body keys:
  /// - conversation_type: e.g. "parent_driver"
  /// - student: int id
  /// - vehicle: int id
  /// - route: int id
  /// - title: string
  /// - description: string
  /// - is_moderated: bool
  /// - moderator: nullable int (or null)
  /// Optional:
  /// - participant_ids: List<int> (included when using RAW variant)
  static Future<ApiResponse<Map<String, dynamic>>> createConversation({
    required String conversationType,
    required int student,
    required int vehicle,
    required int route,
    required String title,
    required String description,
    required bool isModerated,
    int? moderator,
    List<int>? participantIds,
  }) async {
    final Map<String, dynamic> payload = {
      'conversation_type': conversationType,
      'student': student,
      'vehicle': vehicle,
      'route': route,
      'title': title,
      'description': description,
      'is_moderated': isModerated,
      'moderator': moderator,
    };

    if (participantIds != null && participantIds.isNotEmpty) {
      payload['participant_ids'] = participantIds;
    }

    return ApiResponse<Map<String, dynamic>>.success({}).copyWith(
      await ApiService.post<Map<String, dynamic>>(
        AppConfig.conversationsEndpoint,
        data: payload,
      ),
    );
  }
}

extension _ApiResponseCopy<T> on ApiResponse<T> {
  ApiResponse<T> copyWith(ApiResponse<T> other) {
    return other;
  }
}
