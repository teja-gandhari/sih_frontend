import '../core/network/api_client.dart';
import '../models/feasibility_model.dart';

class FeasibilityService {
  final ApiClient _apiClient;

  FeasibilityService(this._apiClient);

  Future<FeasibilityModel> evaluateApplication(String applicationId) async {
    final response = await _apiClient.post('/analysis/evaluate/$applicationId');
    return FeasibilityModel.fromJson(
      applicationId,
      Map<String, dynamic>.from(response),
    );
  }

  Future<FeasibilityModel> fetchFeasibility(String applicationId) async {
    // Keep this method compatible with callers that request an assessment
    // before one has been persisted.
    final response = await _apiClient.post('/analysis/evaluate/$applicationId');
    return FeasibilityModel.fromJson(
      applicationId,
      Map<String, dynamic>.from(response),
    );
  }
}
