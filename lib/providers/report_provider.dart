import 'package:flutter/material.dart';
import '../services/report_service.dart';

enum ReportState { initial, loading, success, error }

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService;

  ReportState _state = ReportState.initial;
  String? _errorMessage;
  Map<String, dynamic>? _report;

  ReportProvider(this._reportService);

  ReportState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get report => _report;

  Future<void> generateReport(String applicationId) async {
    _state = ReportState.loading;
    _errorMessage = null;
    _report = null;
    notifyListeners();

    try {
      _report = await _reportService.generateReport(applicationId);
      _state = ReportState.success;
    } catch (e) {
      _errorMessage = 'Unable to generate the report right now.';
      _state = ReportState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = ReportState.initial;
    _errorMessage = null;
    _report = null;
    notifyListeners();
  }
}
