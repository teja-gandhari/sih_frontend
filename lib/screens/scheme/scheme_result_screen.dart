import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/scheme_provider.dart';

import '../../widgets/app_button.dart';

class SchemeResultScreen extends StatefulWidget {
  const SchemeResultScreen({super.key});

  @override
  State<SchemeResultScreen> createState() => _SchemeResultScreenState();
}

class _SchemeResultScreenState extends State<SchemeResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppStateProvider>();
      if (appState.applicationId != null) {
        context.read<SchemeProvider>().fetchScheme(appState.applicationId!);
      }
    });
    _initTts();
  }

  Future<void> _initTts() async {
    final lang = context.read<AppStateProvider>().selectedLanguage;
    final ttsLocale = switch (lang) {
      'te' => 'te-IN',
      'hi' => 'hi-IN',
      _ => 'en-IN',
    };
    await _flutterTts.setLanguage(ttsLocale);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _flutterTts.speak(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = context.watch<AppStateProvider>();
    final schemeState = context.watch<SchemeProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(loc.get('scheme_result_title'))),
      body: SafeArea(child: _buildBody(appState, schemeState, loc)),
    );
  }

  Widget _buildBody(
      AppStateProvider appState, SchemeProvider schemeState, AppLocalizations loc) {
    if (appState.applicationId == null) {
      return Center(child: Text(loc.get('no_application_found')));
    }

    if (schemeState.state == SchemeState.initial ||
        schemeState.state == SchemeState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loc.get('finding_suitable_scheme')),
          ],
        ),
      );
    }

    if (schemeState.state == SchemeState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                schemeState.errorMessage ?? loc.get('unable_to_determine_scheme'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: loc.get('retry'),
                onPressed: () =>
                    schemeState.fetchScheme(appState.applicationId!),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.get('back')),
              ),
            ],
          ),
        ),
      );
    }

    final data = schemeState.schemeData!;
    final explanation = data.reason;
    final speechText = switch (AppLocalizations.of(context).locale.languageCode) {
      'te' => 'మీ ప్రాజెక్ట్ ${data.schemeName} స్కీమ్‌కి అర్హత పొందింది. $explanation',
      'hi' => 'आपका प्रोजेक्ट ${data.schemeName} स्कीम के लिए योग्य है। $explanation',
      _ => 'Your project qualifies for the ${data.schemeName}. $explanation',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get('recommended_scheme').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('🏦', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          data.schemeName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        data.isEligible ? Icons.check_circle : Icons.warning,
                        color: data.isEligible ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.isEligible
                            ? loc.get('suitable_for_project')
                            : loc.get('not_eligible'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: data.isEligible ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Financial Breakdown
                  _buildRow(
                    loc.get('project_cost'),
                    _currencyFormat.format(data.projectCost),
                  ),
                  _buildRow(
                    loc.get('your_contribution'),
                    _currencyFormat.format(data.marginContribution),
                  ),
                  _buildRow(
                    loc.get('maximum_loan'),
                    _currencyFormat.format(data.maximumLoanAmount),
                  ),

                  const Divider(height: 32),
                  // Loan Terms
                  Text(
                    loc.get('loan_terms').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRow(loc.get('interest_rate'), '${data.interestRate}%'),
                  _buildRow(loc.get('tenure'), '${data.tenure} years'),
                  _buildRow(loc.get('moratorium'), '${data.moratorium} months'),

                  const Divider(height: 32),
                  // Explanation
                  Text(
                    loc.get('why_this_scheme'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(explanation, style: const TextStyle(fontSize: 16)),

                  if (data.benefits.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      loc.get('scheme_benefits').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...data.benefits.map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(child: Text(b)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (data.warnings.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      loc.get('eligibility_warnings').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...data.warnings.map(
                      (w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w,
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _speak(speechText),
                      icon: Icon(
                        _isPlaying ? Icons.stop_circle : Icons.volume_up,
                      ),
                     label: Text(loc.get('listen')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: loc.get('continue_to_market_analysis'),
            onPressed: () {
              Navigator.of(context).pushNamed('/market');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
