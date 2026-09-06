import '../core/network/api_client.dart';
import '../models/market_model.dart';

class MarketService {
  final ApiClient _apiClient;

  MarketService(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchDistricts() async {
    final response = await _apiClient.get('/market/districts');
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchSubDistricts(
    String districtId,
  ) async {
    final response = await _apiClient.get(
      '/market/sub-districts?district_id=$districtId',
    );
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchVillages(String subDistrictId) async {
    final response = await _apiClient.get(
      '/market/villages?sub_district_id=$subDistrictId',
    );
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<MarketModel> fetchMarketAnalysis(String applicationId) async {
    final response = await _apiClient.get(
      '/market/application/$applicationId/indicators',
    );
    return MarketModel.fromJson(
      applicationId,
      Map<String, dynamic>.from(response),
    );
  }
}
