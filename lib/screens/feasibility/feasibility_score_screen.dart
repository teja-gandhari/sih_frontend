import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/feasibility_provider.dart';

import '../../widgets/app_button.dart';

class FeasibilityScoreScreen extends StatefulWidget {
  const FeasibilityScoreScreen({super.key});

  @override
  State<FeasibilityScoreScreen> createState() => _FeasibilityScoreScreenState();
}

class _FeasibilityScoreScreenState extends State<FeasibilityScoreScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppStateProvider>();
      if (appState.applicationId != null) {
        context.read<FeasibilityProvider>().fetchAnalysis(
          appState.applicationId!,
        );
      }
    });
    _initTts();
  }

  Future<void> _initTts() async {
    final langCode = context.read<AppStateProvider>().selectedLanguage;
    await _flutterTts.setLanguage(
      langCode == 'te'
          ? 'te-IN'
          : (langCode == 'hi' ? 'hi-IN' : 'en-IN'),
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
    final feasibilityState = context.watch<FeasibilityProvider>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.get('feasibility_analysis_title'))),
      body: SafeArea(child: _buildBody(appState, feasibilityState, loc)),
    );
  }

  Widget _buildBody(
    AppStateProvider appState,
    FeasibilityProvider feasibilityState,
    AppLocalizations loc,
  ) {
    if (appState.applicationId == null) {
      return Center(child: Text(loc.get('no_application_found')));
    }

    if (feasibilityState.state == FeasibilityState.initial ||
        feasibilityState.state == FeasibilityState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loc.get('evaluating_business')),
          ],
        ),
      );
    }

    if (feasibilityState.state == FeasibilityState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                feasibilityState.errorMessage ??
                    loc.get('unable_feasibility_assessment'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: loc.get('retry'),
                onPressed: () =>
                    feasibilityState.fetchAnalysis(appState.applicationId!),
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

    final data = feasibilityState.feasibilityData!;

    String topRisk = data.riskWarnings.isNotEmpty
        ? data.riskWarnings.first
        : 'None';
    String topRec = data.recommendations.isNotEmpty
        ? data.recommendations.first
        : 'None';
    final speechText =
        'Your overall business score is ${data.overallScore} out of 100, which means it is ${data.viabilityRating}. '
        '${data.explanation} A major risk to consider is $topRisk. A key recommendation is $topRec.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: _getColorForRating(data.viabilityRating).withAlpha(26),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    loc.get('your_business_feasibility'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: data.overallScore / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getColorForRating(data.viabilityRating),
                          ),
                        ),
                      ),
                      Text(
                        '${data.overallScore}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _getColorForRating(data.viabilityRating),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data.viabilityRating,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getColorForRating(data.viabilityRating),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.explanation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _speak(speechText),
                    icon: Icon(
                      _isPlaying ? Icons.stop_circle : Icons.volume_up,
                    ),
                    label: Text(loc.get('listen_to_summary')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (data.marketGap != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.get('market_gap'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      data.marketGap!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Score Breakdown
          _buildSectionCard(
            title: 'SCORE BREAKDOWN',
            icon: Icons.bar_chart,
            child: Column(
              children: [
                _buildScoreBar('Financial', data.financialScore),
                _buildScoreBar('Market', data.marketScore),
                _buildScoreBar('Scheme', data.schemeScore),
                _buildScoreBar('Risk', data.riskScore),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SWOT Analysis
          _buildSectionCard(
            title: 'SWOT ANALYSIS',
            icon: Icons.dashboard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSwotList(
                  'Strengths',
                  data.strengths,
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildSwotList(
                  'Weaknesses',
                  data.weaknesses,
                  Icons.warning,
                  Colors.orange,
                ),
                _buildSwotList(
                  'Opportunities',
                  data.opportunities,
                  Icons.lightbulb,
                  Colors.blue,
                ),
                _buildSwotList(
                  'Threats',
                  data.threats,
                  Icons.dangerous,
                  Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Risks
          if (data.riskWarnings.isNotEmpty)
            _buildSectionCard(
              title: 'KEY RISKS',
              icon: Icons.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.riskWarnings
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                r,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Recommendations
          if (data.recommendations.isNotEmpty)
            _buildSectionCard(
              title: 'RECOMMENDATIONS',
              icon: Icons.check,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.recommendations
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right, color: Colors.green),
                            Expanded(
                              child: Text(
                                r,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),

          const Text(
            'Note: These indicators are estimates intended to support business planning. This is a decision-support tool, not a guarantee of business success.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            text: 'Continue to AI Advisor',
            onPressed: () {
              Navigator.of(context).pushNamed('/advisor');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$score / 100'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 80
                  ? Colors.green
                  : score >= 60
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwotList(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(i)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRating(String rating) {
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
