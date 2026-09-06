import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/financial_model.dart';

class FinancialService {
  final ApiClient _apiClient;

  FinancialService(this._apiClient);

  Future<FinancialModel> calculateStandalone(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      '/financial/calculate',
      body: payload,
    );
    return FinancialModel.fromJson('', Map<String, dynamic>.from(response));
  }

  Future<FinancialModel> fetchFinancialAnalysis(String applicationId) async {
    try {
      final response = await _apiClient.get('/financial/application/$applicationId');
      return FinancialModel.fromJson(
        applicationId,
        Map<String, dynamic>.from(response),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        final response = await _apiClient.post(
          '/financial/application/$applicationId/calculate',
        );
        return FinancialModel.fromJson(
          applicationId,
          Map<String, dynamic>.from(response),
        );
      }
      rethrow;
    }
  }

  Future<FinancialModel> getSavedFinancialAnalysis(String applicationId) async {
    final response = await _apiClient.get(
      '/financial/application/$applicationId',
    );
    return FinancialModel.fromJson(
      applicationId,
      Map<String, dynamic>.from(response),
    );
  }
}
