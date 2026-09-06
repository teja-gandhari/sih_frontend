import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/router.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/financial_provider.dart';
import '../../providers/scheme_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/feasibility_provider.dart';
import '../../providers/advisory_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/market_model.dart';
import '../../widgets/app_button.dart';

class FinalDashboardScreen extends StatefulWidget {
  const FinalDashboardScreen({super.key});

  @override
  State<FinalDashboardScreen> createState() => _FinalDashboardScreenState();
}

class _FinalDashboardScreenState extends State<FinalDashboardScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  bool _isPlaying = false;
  bool _isLoadingAll = true;

  @override
  void initState() {
    super.initState();
    _checkDataSync();
    _initTts();
  }

  Future<void> _checkDataSync() async {
    // Ensuring all data is present for the current application.
    // Realistically, the user traversed the steps, so data is already in providers.
    setState(() {
      _isLoadingAll = false;
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage(
      context.read<AppStateProvider>().selectedLanguage == 'en'
          ? 'en-IN'
          : 'hi-IN',
    );
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
    final appState = context.watch<AppStateProvider>();
    final finState = context.watch<FinancialProvider>();
    final schemeState = context.watch<SchemeProvider>();
    final marketState = context.watch<MarketProvider>();
    final feasState = context.watch<FeasibilityProvider>();
    final advState = context.watch<AdvisoryProvider>();
    final reportState = context.watch<ReportProvider>();

    final loc = AppLocalizations.of(context);

    if (appState.applicationId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.get('final_dashboard_title'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No business application selected.'),
              const SizedBox(height: 16),
              AppButton(
                text: loc.get('start_application'),
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRouter.language),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingAll) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(loc.get('preparing_report')),
            ],
          ),
        ),
      );
    }

    // Safety checks for incomplete data
    final isFinMissing = finState.financialData == null;
    final isFeasMissing = feasState.feasibilityData == null;

    if (isFinMissing || isFeasMissing) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.get('final_dashboard_title'))),
        body: Center(
          child: Text(
            loc.get('analysis_incomplete'),
          ),
        ),
      );
    }

    final feas = feasState.feasibilityData!;
    final fin = finState.financialData!;
    final scheme = schemeState.schemeData;
    final market = marketState.marketData;

    // AI recommendation snapshot
    String aiRec = 'AI advisory available.';
    if (advState.messages.isNotEmpty) {
      final lastAi = advState.messages.lastWhere(
        (m) => !m.isUser,
        orElse: () => advState.messages.first,
      );
      if (!lastAi.isUser) {
        aiRec = lastAi.text.length > 100
            ? '${lastAi.text.substring(0, 100)}...'
            : lastAi.text;
      }
    }

    // TTS String
    final summaryText =
        'Your business ${appState.businessCategory?.name} in ${appState.village} has an overall feasibility score of ${feas.overallScore} out of 100. '
        'Your loan requirement is ${_currencyFormat.format(fin.maximumLoanAmount)}. '
        'Major risk: ${feas.riskWarnings.isNotEmpty ? feas.riskWarnings.first : 'None'}. '
        'Recommendation: ${feas.recommendations.isNotEmpty ? feas.recommendations.first : 'Proceed with caution.'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Final Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(
                appState.businessCategory?.name ?? '',
                appState.village ?? '',
                appState.block ?? '',
                appState.district ?? '',
                loc,
              ),
              const SizedBox(height: 16),

              // Executive Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Your business has ${feas.viabilityRating.toLowerCase()} viability. ${feas.explanation}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Overall Feasibility
              _buildFeasibilityCard(
                feas.overallScore,
                feas.viabilityRating,
                context,
                loc,
              ),
              const SizedBox(height: 16),

              // Financial Snapshot
              _buildFinancialSnapshot(fin, context, loc),
              const SizedBox(height: 16),

              // Scheme
              if (scheme != null)
                _buildSchemeSnapshot(scheme, context, loc)
              else
                _buildMissingSection('Scheme Data Missing', '/scheme', context, loc),
              const SizedBox(height: 16),

              // Market
              if (market != null)
                _buildMarketSnapshot(market, context, loc)
              else
                _buildMissingSection('Market Data Missing', '/market', context, loc),
              const SizedBox(height: 16),

              // Risks & Opportunities (SWOT Summary)
              _buildRiskOpportunitySnapshot(
                feas.riskWarnings,
                feas.opportunities,
                context,
                loc,
              ),
              const SizedBox(height: 16),

              // AI Recommendation
              _buildAiRecommendation(aiRec, context, loc),
              const SizedBox(height: 16),

              // Business Decision
              _buildBusinessDecision(feas.viabilityRating, loc),
              const SizedBox(height: 24),

              // Report Generation
              _buildReportSection(reportState, appState.applicationId!, loc),
              const SizedBox(height: 24),

              // Listen
              ElevatedButton.icon(
                onPressed: () => _speak(summaryText),
                icon: Icon(_isPlaying ? Icons.stop_circle : Icons.volume_up),
                label: Text(loc.get('listen_to_summary')),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: loc.get('go_to_home'),
                onPressed: () =>
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (route) => false),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String business,
    String village,
    String block,
    String district,
    AppLocalizations loc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.get('ruralbiz_ai'),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          loc.get('business_feasibility_summary'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.store, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              business,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$village\n$block, $district',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeasibilityCard(
    int score,
    String rating,
    BuildContext context,
    AppLocalizations loc,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              loc.get('overall_feasibility'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              '$score / 100',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text(
              rating,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(rating),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/feasibility'),
              child: Text(loc.get('view_full_analysis')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSnapshot(dynamic fin, BuildContext context, AppLocalizations loc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('financial_snapshot'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const Divider(),
            _buildRow(
              loc.get('available_margin'),
              _currencyFormat.format(fin.availableMarginCapital),
            ),
            _buildRow(
              loc.get('project_cost'),
              _currencyFormat.format(fin.totalFeasibleProjectCost),
            ),
            _buildRow(
              loc.get('loan_requirement'),
              _currencyFormat.format(fin.maximumLoanAmount),
              highlight: true,
            ),
            _buildRow(loc.get('emi'), _currencyFormat.format(fin.monthlyEmi)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/financial'),
                child: Text(loc.get('view_financial_analysis')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeSnapshot(dynamic scheme, BuildContext context, AppLocalizations loc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('scheme_label'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const Divider(),
            Text(
              scheme.schemeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${scheme.interestRate}% interest • ${scheme.tenure} years • ${scheme.moratorium}-month moratorium',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/scheme'),
                child: Text(loc.get('view_scheme')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketSnapshot(MarketModel market, BuildContext context, AppLocalizations loc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('local_market_estimated'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const Divider(),
            _buildRow(
              loc.get('demand_index'),
              '${market.demandIndex.toStringAsFixed(1)} / 10',
              highlight: true,
            ),
            _buildRow(loc.get('competitors'), market.competitorCount.toString()),
            _buildRow(loc.get('market_opportunity'), market.opportunityClassification),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/market'),
                child: Text(loc.get('view_market_analysis')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskOpportunitySnapshot(
    List<String> risks,
    List<String> opportunities,
    BuildContext context,
    AppLocalizations loc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get('key_risks'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...risks
                      .take(2)
                      .map(
                        (r) =>
                            Text('⚠ $r', style: const TextStyle(fontSize: 12)),
                      ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get('opportunities'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...opportunities
                      .take(2)
                      .map(
                        (o) =>
                            Text('✓ $o', style: const TextStyle(fontSize: 12)),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiRecommendation(String recommendation, BuildContext context, AppLocalizations loc) {
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  loc.get('ai_advisory'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"$recommendation"',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              loc.get('ai_guidance_note'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/advisor'),
                child: Text(loc.get('ask_ai_advisor')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDecision(String viabilityRating, AppLocalizations loc) {
    String decision = loc.get('review_risks');
    IconData decisionIcon = Icons.warning;
    Color decisionColor = Colors.orange;

    final lower = viabilityRating.toLowerCase();
    if (lower.contains('high') ||
        lower.contains('strong') ||
        lower == 'feasible') {
      decision = loc.get('proceed');
      decisionIcon = Icons.check_circle;
      decisionColor = Colors.green;
    } else if (lower.contains('moderate')) {
      decision = loc.get('proceed_with_caution');
    } else if (lower.contains('low') || lower.contains('unfeasible')) {
      decision = loc.get('not_recommended');
      decisionIcon = Icons.cancel;
      decisionColor = Colors.red;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: decisionColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(decisionIcon, color: decisionColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get('business_decision'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    decision,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: decisionColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareReport(ReportProvider reportState) async {
    final localeCode = context.read<AppStateProvider>().selectedLanguage;
    final bytes = await _buildReportPdf(reportState.report, localeCode);
    if (bytes == null) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'business_feasibility_report.pdf',
    );
  }

  Future<void> _downloadReport(ReportProvider reportState) async {
    final localeCode = context.read<AppStateProvider>().selectedLanguage;
    final bytes = await _buildReportPdf(reportState.report, localeCode);
    if (bytes == null || !mounted) return;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/business_feasibility_report.pdf');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).get('report_saved_to').replaceAll('%s', file.path))),
    );
  }

  Future<Uint8List?> _buildReportPdf(Map<String, dynamic>? report, [String localeCode = 'en']) async {
    if (report == null) return null;
    final title = localeCode == 'te'
        ? 'వ్యాపార సాధ్యత నివేదిక'
        : (localeCode == 'hi' ? 'व्यवसाय व्यवहार्यता रिपोर्ट' : 'Business Feasibility Report');
    final reportIdLabel = localeCode == 'te'
        ? 'రిపోర్ట్ ఐడి:'
        : (localeCode == 'hi' ? 'रिपोर्ट आईडी:' : 'Report ID:');
    final financialSummaryLabel = localeCode == 'te'
        ? 'ఆర్థిక సారాంశం'
        : (localeCode == 'hi' ? 'वित्तीय सारांश' : 'Financial Summary');
    final marketViabilityLabel = localeCode == 'te'
        ? 'మార్కెట్ మరియు సాధ్యత'
        : (localeCode == 'hi' ? 'बाजार और व्यवहार्यता' : 'Market and Viability');
    final recommendationsLabel = localeCode == 'te'
        ? 'సిఫార్సులు'
        : (localeCode == 'hi' ? 'सिफारिशें' : 'Recommendations');
    final document = pw.Document();
    final lines = <String>[
      report['report_title']?.toString() ?? title,
      '$reportIdLabel ${report['report_id'] ?? '-'}',
      '',
      financialSummaryLabel,
      ..._reportSectionLines(report['financial_summary']),
      '',
      marketViabilityLabel,
      ..._reportSectionLines(report['market_and_viability']),
      '',
      recommendationsLabel,
      ..._reportListLines(report['recommendations']),
    ];
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, text: lines.first),
          ...lines.skip(1).map((line) => pw.Paragraph(text: line)),
        ],
      ),
    );
    return document.save();
  }

  List<String> _reportSectionLines(dynamic section) {
    if (section is! Map) return const ['Not available'];
    return section.entries.map((entry) => '${entry.key}: ${entry.value}').toList();
  }

  List<String> _reportListLines(dynamic values) {
    if (values is! List || values.isEmpty) return const ['None'];
    return values.map((value) => '- $value').toList();
  }

  Widget _buildReportSection(ReportProvider reportState, String applicationId, AppLocalizations loc) {
    return Column(
      children: [
        if (reportState.state == ReportState.loading)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(loc.get('preparing_report')),
              ],
            ),
          )
        else if (reportState.state == ReportState.error)
          Column(
            children: [
              Text(
                reportState.errorMessage ?? 'Error',
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: () => context.read<ReportProvider>().generateReport(
                  applicationId,
                ),
                child: Text(loc.get('retry')),
              ),
            ],
          )
        else if (reportState.state == ReportState.success)
          Column(
            children: [
              Text(
                loc.get('report_generated_successfully'),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                text: loc.get('view_report_details'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.get('report_is_ready')),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              AppButton(
                text: loc.get('share_pdf_report'),
                onPressed: () => _shareReport(reportState),
              ),
              const SizedBox(height: 8),
              AppButton(
                text: loc.get('download_pdf'),
                onPressed: () => _downloadReport(reportState),
              ),
            ],
          )
        else
          AppButton(
            text: loc.get('generate_business_report'),
            onPressed: () =>
                context.read<ReportProvider>().generateReport(applicationId),
          ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.blue : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingSection(
    String message,
    String route,
    BuildContext context,
    AppLocalizations loc,
  ) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(route),
              child: Text(loc.get('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(String rating) {
    final lower = rating.toLowerCase();
    if (lower.contains('highly') || lower.contains('strong')) {
      return Colors.green.shade700;
    }
    if (lower.contains('feasible')) {
      return Colors.green;
    }
    if (lower.contains('moderate') || lower.contains('medium')) {
      return Colors.orange;
    }
    if (lower.contains('risk') ||
        lower.contains('weak') ||
        lower.contains('unfeasible')) {
      return Colors.red;
    }
    return Colors.blue;
  }
}
