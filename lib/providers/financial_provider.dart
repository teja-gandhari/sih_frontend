import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/financial_model.dart';
import '../services/financial_service.dart';

enum FinancialState { initial, loading, loaded, error }

class FinancialProvider extends ChangeNotifier {
  final FinancialService _financialService;

  FinancialState _state = FinancialState.initial;
  FinancialModel? _financialData;
  String? _errorMessage;

  FinancialProvider(this._financialService);

  FinancialState get state => _state;
  FinancialModel? get financialData => _financialData;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAnalysis(String applicationId) async {
    // Stale data protection: if new application, clear old data immediately.
    if (_financialData != null && _financialData!.applicationId != applicationId) {
      _financialData = null;
    }

    if (_financialData != null && _financialData!.applicationId == applicationId) {
      // Already fetched and valid for this application
      return;
    }

    _state = FinancialState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _financialService.fetchFinancialAnalysis(applicationId);
      
      // Double check stale protection in case application changed during async call
      if (result.applicationId == applicationId) {
        _financialData = result;
        _state = FinancialState.loaded;
      }
    } catch (e) {
      final message = e is ApiException ? e.message : 'Unable to calculate your financial plan.';
      _errorMessage = message.isNotEmpty ? message : 'Unable to calculate your financial plan.';
      _state = FinancialState.error;
    }
    notifyListeners();
  }

  void clear() {
    _state = FinancialState.initial;
    _financialData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
