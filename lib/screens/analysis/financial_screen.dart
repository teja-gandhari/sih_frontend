import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/financial_provider.dart';
import '../../models/financial_model.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/repayment_schedule_widget.dart';
import '../../widgets/app_button.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
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
        context.read<FinancialProvider>().fetchAnalysis(
          appState.applicationId!,
        );
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

  String _generateExplanation(FinancialModel model, AppLocalizations loc) {
    final pct =
        (model.availableMarginCapital / model.totalFeasibleProjectCost * 100)
            .toStringAsFixed(0);
    final amount = _currencyFormat.format(model.availableMarginCapital);
    final projectCost = _currencyFormat.format(model.totalFeasibleProjectCost);
    final loanNeed = _currencyFormat.format(model.maximumLoanAmount);

    switch (loc.locale.languageCode) {
      case 'te':
        return 'మీ $amount సహకారం ప్రాజెక్ట్ ఖర్చులో $pct%గా ఉంది. ప్రస్తుత ఆర్థిక నియమాల ప్రకారం, అంచనా ప్రాజెక్ట్ ఖర్చు $projectCost మరియు లోన్ అవసరం $loanNeed.';
      case 'hi':
        return 'आपका $amount योगदान प्रोजेक्ट लागत का $pct% है। वर्तमान वित्तीय नियमों के अनुसार, अनुमानित प्रोजेक्ट लागत $projectCost है और आवश्यक वित्तीय सहायता $loanNeed है।';
      default:
        return 'Your $amount contribution represents $pct% of the project cost. '
            'Based on the current financial rules, the estimated project cost is $projectCost '
            'and the financing requirement is $loanNeed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = context.watch<AppStateProvider>();
    final finState = context.watch<FinancialProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(loc.get('financial_analysis_title'))),
      body: SafeArea(child: _buildBody(appState, finState, loc)),
    );
  }

  Widget _buildBody(
      AppStateProvider appState, FinancialProvider finState, AppLocalizations loc) {
    if (appState.applicationId == null) {
      return Center(child: Text(loc.get('no_application_found')));
    }

    if (finState.state == FinancialState.initial ||
        finState.state == FinancialState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loc.get('calculating_your_plan')),
          ],
        ),
      );
    }

    if (finState.state == FinancialState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                finState.errorMessage ?? loc.get('unable_to_calculate_plan'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: loc.get('continue_to_scheme'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/scheme');
                },
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

    final data = finState.financialData!;
    final explanation = _generateExplanation(data, loc);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business Summary Context
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get('business_summary').toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${loc.get('business_label')}: ${appState.businessCategory?.name ?? loc.get('unknown')}',
                  ),
                  Text('${loc.get('location_label')}: ${appState.village ?? loc.get('unknown')}'),
                  Text(
                    '${loc.get('margin_capital_label')}: ${_currencyFormat.format(appState.marginCapital ?? 0)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Explanation and Listen
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.get('financial_explanation'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.stop_circle : Icons.volume_up,
                        color: Colors.blue,
                      ),
                      onPressed: () => _speak(explanation),
                      tooltip: loc.get('listen_to_financial_summary'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  explanation,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              MetricCard(
                title: loc.get('available_margin'),
                value: _currencyFormat.format(data.availableMarginCapital),
              ),
              MetricCard(
                title: loc.get('project_cost'),
                value: _currencyFormat.format(data.totalFeasibleProjectCost),
              ),
              MetricCard(
                title: loc.get('maximum_loan'),
                value: _currencyFormat.format(data.maximumLoanAmount),
              ),
              MetricCard(
                title: loc.get('interest_rate'),
                value: '${data.interestRate}%',
              ),
              MetricCard(
                title: loc.get('tenure'),
                value: '${data.tenure} years',
              ),
              MetricCard(
                title: loc.get('moratorium'),
                value: '${data.moratorium} months',
              ),
              MetricCard(
                title: loc.get('monthly_emi'),
                value: _currencyFormat.format(data.monthlyEmi),
              ),
              MetricCard(
                title: loc.get('quarterly'),
                value: _currencyFormat.format(data.quarterlyInstallment),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Repayment Schedule
          if (data.repaymentSchedule.isNotEmpty)
            RepaymentScheduleWidget(schedule: data.repaymentSchedule),
          const SizedBox(height: 24),
          AppButton(
            text: loc.get('continue_to_scheme'),
            onPressed: () {
              Navigator.of(context).pushNamed('/scheme');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
