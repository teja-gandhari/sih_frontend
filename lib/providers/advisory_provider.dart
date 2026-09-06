import 'package:flutter/material.dart';
import '../models/advisory_model.dart';
import '../services/advisory_service.dart';

enum AdvisoryState { initial, loading, loaded, error }

class AdvisoryProvider extends ChangeNotifier {
  final AdvisoryService _advisoryService;

  String? _currentApplicationId;
  final List<ChatMessage> _messages = [];
  AdvisoryState _state = AdvisoryState.initial;
  String? _errorMessage;

  AdvisoryProvider(this._advisoryService);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  AdvisoryState get state => _state;
  String? get errorMessage => _errorMessage;

  void initialize(String applicationId) {
    if (_currentApplicationId != applicationId) {
      _currentApplicationId = applicationId;
      _messages.clear();
      _state = AdvisoryState.initial;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message, String language) async {
    if (_currentApplicationId == null || message.trim().isEmpty) return;
    if (_state == AdvisoryState.loading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _state = AdvisoryState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final aiResponse = await _advisoryService.askQuestion(
        _currentApplicationId!,
        message,
        language,
      );
      _messages.add(aiResponse);
      _state = AdvisoryState.loaded;
    } catch (e) {
      _errorMessage = e.toString().contains('Exception: ')
          ? e.toString().split('Exception: ')[1]
          : 'Unable to get advice right now.';
      _state = AdvisoryState.error;
    }
    notifyListeners();
  }

  void clear() {
    _currentApplicationId = null;
    _messages.clear();
    _state = AdvisoryState.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
