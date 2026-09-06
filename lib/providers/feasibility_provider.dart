import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/feasibility_model.dart';
import '../services/feasibility_service.dart';

enum FeasibilityState { initial, loading, loaded, error }

class FeasibilityProvider extends ChangeNotifier {
  final FeasibilityService _feasibilityService;

  FeasibilityState _state = FeasibilityState.initial;
  FeasibilityModel? _feasibilityData;
  String? _errorMessage;

  FeasibilityProvider(this._feasibilityService);

  FeasibilityState get state => _state;
  FeasibilityModel? get feasibilityData => _feasibilityData;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAnalysis(String applicationId) async {
    // Stale data protection
    if (_feasibilityData != null && _feasibilityData!.applicationId != applicationId) {
      _feasibilityData = null;
    }

    if (_feasibilityData != null && _feasibilityData!.applicationId == applicationId) {
      return;
    }

    _state = FeasibilityState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // An application is evaluated only after its financial and market inputs
      // have been calculated. The GET endpoint is for already-saved results.
      final result = await _feasibilityService.evaluateApplication(applicationId);
      
      // Match ID logic
      if (result.applicationId == applicationId) {
        _feasibilityData = result;
        _state = FeasibilityState.loaded;
      }
    } catch (e) {
      _errorMessage = e is ApiException && e.message.isNotEmpty
          ? e.message
          : 'Unable to complete the feasibility assessment.';
      _state = FeasibilityState.error;
    }
    notifyListeners();
  }

  void clear() {
    _state = FeasibilityState.initial;
    _feasibilityData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
