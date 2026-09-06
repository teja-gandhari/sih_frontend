import '../core/network/api_client.dart';
import '../models/advisory_model.dart';

class AdvisoryService {
  final ApiClient _apiClient;

  AdvisoryService(this._apiClient);

  Future<ChatMessage> askQuestion(
    String applicationId,
    String message,
    String language,
  ) async {
    final response = await _apiClient
        .post(
          '/advisory/query',
          body: {
            'application_id': applicationId,
            'query_text': message,
            'language': language,
          },
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw Exception(
              'AI Advisor is taking longer than expected. Please try again.',
            );
          },
        );
    return ChatMessage.fromJson(
      Map<String, dynamic>.from(response),
      isUser: false,
    );
  }
}
