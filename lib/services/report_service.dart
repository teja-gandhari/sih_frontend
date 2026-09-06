import '../core/network/api_client.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<Map<String, dynamic>> generateReport(String applicationId) async {
    final response = await _apiClient.get('/analysis/$applicationId/report');
    return Map<String, dynamic>.from(response as Map);
  }
}
