import '../core/network/api_client.dart';
import '../models/onboarding_models.dart';

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService(this._apiClient);

  Future<List<BusinessCategory>> fetchCategories() async {
    final response = await _apiClient.get('/businesses/sectors');
    if (response is List) {
      return response
          .map((e) => BusinessCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<List<BusinessTemplate>> fetchTemplates(String categoryId) async {
    final response = await _apiClient.get('/businesses/types?sector_code=$categoryId');
    if (response is List) {
      return response
          .map((e) => BusinessTemplate.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<String> createApplication(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/businesses/applications', body: data);
    if (response != null && response['id'] != null) {
       return response['id'].toString();
    }
    throw Exception('Failed to create application');
  }

  Future<void> saveProfileLocation({
    required String village,
    required String subDistrict,
    required String district,
  }) async {
    await _apiClient.put('/users/profile', body: {
      'village': village,
      'sub_district': subDistrict,
      'district': district,
    });
  }
}
