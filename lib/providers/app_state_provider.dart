import 'package:flutter/material.dart';
import '../models/onboarding_models.dart';

class AppStateProvider extends ChangeNotifier {
  String _selectedLanguage = 'en';
  String get selectedLanguage => _selectedLanguage;

  String? _village;
  String? get village => _village;

  String? _block;
  String? get block => _block;

  String? _district;
  String? get district => _district;

  String? _state;
  String? get state => _state;

  String? _districtId;
  String? get districtId => _districtId;

  String? _subDistrictId;
  String? get subDistrictId => _subDistrictId;

  String? _villageId;
  String? get villageId => _villageId;

  double? _marginCapital;
  double? get marginCapital => _marginCapital;

  BusinessCategory? _businessCategory;
  BusinessCategory? get businessCategory => _businessCategory;

  BusinessTemplate? _businessTemplate;
  BusinessTemplate? get businessTemplate => _businessTemplate;

  String? _customBusinessPlan;
  String? get customBusinessPlan => _customBusinessPlan;

  String? _applicationId;
  String? get applicationId => _applicationId;

  int? _scaleUnits;
  int? get scaleUnits => _scaleUnits;

  final List<Map<String, String>> _recentApplications = [];
  List<Map<String, String>> get recentApplications =>
      List.unmodifiable(_recentApplications);

  void addApplicationSummary({
    required String applicationId,
    required String businessName,
    required String location,
  }) {
    final entry = {
      'applicationId': applicationId,
      'businessName': businessName,
      'location': location,
    };

    final existingIndex = _recentApplications.indexWhere(
      (item) => item['applicationId'] == applicationId,
    );
    if (existingIndex >= 0) {
      _recentApplications.removeAt(existingIndex);
    }

    _recentApplications.insert(0, entry);
    if (_recentApplications.length > 5) {
      _recentApplications.removeRange(5, _recentApplications.length);
    }
    notifyListeners();
  }

  void removeApplicationSummary(String applicationId) {
    _recentApplications.removeWhere((item) => item['applicationId'] == applicationId);
    notifyListeners();
  }

  final List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String search) {
    final normalized = search.trim();
    if (normalized.isEmpty) return;
    _recentSearches.remove(normalized);
    _recentSearches.insert(0, normalized);
    if (_recentSearches.length > 5) {
      _recentSearches.removeRange(5, _recentSearches.length);
    }
    notifyListeners();
  }

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    notifyListeners();
  }

  void setLocation(
    String village,
    String block,
    String district, {
    String? villageId,
    String? subDistrictId,
    String? districtId,
    String? state,
  }) {
    _village = village;
    _block = block;
    _district = district;
    _state = state;
    _villageId = villageId;
    _subDistrictId = subDistrictId;
    _districtId = districtId;
    notifyListeners();
  }

  void setMarginCapital(double amount) {
    _marginCapital = amount;
    notifyListeners();
  }

  void setBusinessCategory(BusinessCategory category) {
    _businessCategory = category;
    _businessTemplate = null; // reset template when category changes
    notifyListeners();
  }

  void setBusinessTemplate(BusinessTemplate template, {String? customPlan}) {
    _businessTemplate = template;
    _customBusinessPlan = customPlan;
    notifyListeners();
  }

  void setApplicationId(String id) {
    _applicationId = id;
    notifyListeners();
  }

  void setScaleUnits(int value) {
    _scaleUnits = value;
    notifyListeners();
  }

  void clearOnboarding() {
    _village = null;
    _block = null;
    _district = null;
    _state = null;
    _districtId = null;
    _subDistrictId = null;
    _villageId = null;
    _marginCapital = null;
    _businessCategory = null;
    _businessTemplate = null;
    _customBusinessPlan = null;
    _applicationId = null;
    _scaleUnits = null;
    notifyListeners();
  }
}
