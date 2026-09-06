import 'package:flutter/material.dart';
import '../models/scheme_model.dart';
import '../services/scheme_service.dart';

enum SchemeState { initial, loading, loaded, error }

class SchemeProvider extends ChangeNotifier {
  final SchemeService _schemeService;

  SchemeState _state = SchemeState.initial;
  SchemeModel? _schemeData;
  String? _errorMessage;

  SchemeProvider(this._schemeService);

  SchemeState get state => _state;
  SchemeModel? get schemeData => _schemeData;
  String? get errorMessage => _errorMessage;

  Future<void> fetchScheme(String applicationId) async {
    // Stale data protection
    if (_schemeData != null && _schemeData!.applicationId != applicationId) {
      _schemeData = null;
    }

    if (_schemeData != null && _schemeData!.applicationId == applicationId) {
      return;
    }

    _state = SchemeState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _schemeService.fetchSchemeResult(applicationId);
      
      // Verify application ID matches before accepting
      if (result.applicationId == applicationId) {
        _schemeData = result;
        _state = SchemeState.loaded;
      }
    } catch (e) {
      _errorMessage = 'Unable to determine the funding scheme.';
      _state = SchemeState.error;
    }
    notifyListeners();
  }

  void clear() {
    _state = SchemeState.initial;
    _schemeData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
