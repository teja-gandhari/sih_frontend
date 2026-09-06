import '../core/network/api_client.dart';
import '../models/scheme_model.dart';

class SchemeService {
  final ApiClient _apiClient;

  SchemeService(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchSchemeCatalog() async {
    final response = await _apiClient.get('/schemes/');
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  Future<SchemeModel> fetchSchemeResult(String applicationId) async {
    final application = await _apiClient.get(
      '/businesses/applications/$applicationId',
    );
    final businessType = Map<String, dynamic>.from(
      application['business_type'] ?? const {},
    );
    final userProfile = await _apiClient.get('/users/me');

    final sectors = await _apiClient.get('/businesses/sectors');
    final sector = (sectors is List)
        ? (sectors.cast<Map<String, dynamic>>().firstWhere(
            (item) => item['id'] == businessType['sector_id'],
            orElse: () => <String, dynamic>{},
          ))
        : <String, dynamic>{};

    final financials = await _apiClient.get('/financial/application/$applicationId');
    final projectCost = (financials['total_project_cost'] as num?)?.toDouble() ?? 0;
    final userMarginAvailable =
        (application['user_margin_available'] as num?)?.toDouble() ??
        (userProfile['available_margin_money'] as num?)?.toDouble() ??
        0;
    final requestBody = {
      'sector_code':
          (sector['code'] as String?) ??
          (businessType['code'] as String?) ??
          'dairy',
      'project_cost': projectCost,
      'user_margin_available': userMarginAvailable,
      'category': userProfile['social_category'] ?? 'general',
      'is_rural': true,
      'applicant_age': 28,
      'education_level': userProfile['education_level'] ?? '10th_pass',
    };

    final response = await _apiClient.post('/schemes/match', body: requestBody);
    if (response is List && response.isNotEmpty) {
      final first = Map<String, dynamic>.from(response.first as Map<String, dynamic>);
      final merged = {
        ...first,
        'project_cost': projectCost,
        'total_project_cost': projectCost,
        'user_margin_amount': userMarginAvailable,
        'net_bank_loan_required': first['net_bank_loan'] ?? financials['net_bank_loan_required'] ?? 0,
        'annual_interest_rate':
            first['estimated_interest_rate'] ?? financials['annual_interest_rate'] ?? 0,
        'loan_tenure_months': financials['loan_tenure_months'] ?? 0,
      };
      return SchemeModel.fromJson(applicationId, merged);
    }

    throw Exception('No scheme recommendation available for this application.');
  }
}
