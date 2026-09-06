import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../models/market_model.dart';
import '../services/market_service.dart';

enum MarketState { initial, loading, loaded, error }

class MarketProvider extends ChangeNotifier {
  final MarketService _marketService;

  MarketState _state = MarketState.initial;
  MarketModel? _marketData;
  String? _errorMessage;

  MarketProvider(this._marketService);

  MarketState get state => _state;
  MarketModel? get marketData => _marketData;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAnalysis(String applicationId) async {
    // Stale data protection
    if (_marketData != null && _marketData!.applicationId != applicationId) {
      _marketData = null;
    }

    if (_marketData != null && _marketData!.applicationId == applicationId) {
      return;
    }

    _state = MarketState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _marketService.fetchMarketAnalysis(applicationId);
      
      // Match ID logic
      if (result.applicationId == applicationId) {
        _marketData = result;
        _state = MarketState.loaded;
      }
    } catch (e) {
      final errorText = e is ApiException
          ? e.message
          : e.toString().replaceFirst('ApiException', '').trim();
      _errorMessage = errorText.isNotEmpty && errorText != '()'
          ? errorText
          : 'Unable to analyze the local market right now.';
      _state = MarketState.error;
    }
    notifyListeners();
  }

  void clear() {
    _state = MarketState.initial;
    _marketData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
