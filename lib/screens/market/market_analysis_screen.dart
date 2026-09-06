import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/market_provider.dart';
import '../../models/market_model.dart';

import '../../widgets/app_button.dart';

class MarketAnalysisScreen extends StatefulWidget {
  const MarketAnalysisScreen({super.key});

  @override
  State<MarketAnalysisScreen> createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends State<MarketAnalysisScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final _numberFormat = NumberFormat('#,##,###');
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppStateProvider>();
      if (appState.applicationId != null) {
        context.read<MarketProvider>().fetchAnalysis(appState.applicationId!);
      }
    });
    _initTts();
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
    final marketState = context.watch<MarketProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Check Your Local Market')),
      body: SafeArea(child: _buildBody(appState, marketState)),
    );
  }

  Widget _buildBody(AppStateProvider appState, MarketProvider marketState) {
    if (appState.applicationId == null) {
      return const Center(child: Text('No application found. Please go back.'));
    }

    if (marketState.state == MarketState.initial ||
        marketState.state == MarketState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing your local market...'),
          ],
        ),
      );
    }

    if (marketState.state == MarketState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                marketState.errorMessage ??
                    'Unable to analyze the local market right now.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Retry',
                onPressed: () =>
                    marketState.fetchAnalysis(appState.applicationId!),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final data = marketState.marketData!;

    final speechText =
        'In your area, customer interest looks ${_demandDescription(data.demandIndex)}. '
          'We found about ${data.competitorCount} similar businesses. '
          '${_opportunitySummary(data)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR AREA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📍 ${appState.village}, ${appState.block}, ${appState.district}',
                  ),
                  Text('🏪 ${appState.businessCategory?.name}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            title: 'AT A GLANCE',
            icon: Icons.lightbulb_outline,
            child: Text(
              'This is an estimate to help you decide. It is not a promise of earnings. '
              'Visit nearby shops and speak with customers before investing.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),

          // Demand and competition
          _buildSectionCard(
            title: 'WILL PEOPLE BUY IT?',
            icon: Icons.people,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow(
                  'Estimated customer interest',
                  _demandDescription(data.demandIndex),
                ),
                _buildRow('Similar businesses nearby', '${data.competitorCount}'),
                const SizedBox(height: 8),
                Text(
                  'Score: ${data.demandIndex.toStringAsFixed(1)} out of 10. '
                  'A higher score means more people may need this service.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Opportunity
          _buildSectionCard(
            title: 'WHAT THIS MEANS',
            icon: Icons.lightbulb,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _opportunityHeadline(data),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getColorForLevel(data.competitionLevel),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _opportunitySummary(data),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),

                const Divider(),
                _buildRow('Nearest market distance', data.mandiDistanceKm == null
                    ? 'Not available'
                    : '${data.mandiDistanceKm!.toStringAsFixed(1)} km'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Purchasing Power & Seasonality
          if (data.purchasingPower != null || data.seasonality != null)
            Row(
              children: [
                if (data.purchasingPower != null)
                  Expanded(
                    child: _buildSectionCard(
                      title: 'CAN PEOPLE AFFORD IT?',
                      icon: Icons.account_balance_wallet,
                      child: Text(
                        _readableValue(data.purchasingPower!),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                if (data.purchasingPower != null && data.seasonality != null)
                  const SizedBox(width: 8),
                if (data.seasonality != null)
                  Expanded(
                    child: _buildSectionCard(
                      title: 'DOES IT CHANGE BY SEASON?',
                      icon: Icons.calendar_month,
                      child: Text(
                        _readableValue(data.seasonality!),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('More details (optional)'),
              subtitle: const Text('Technical information for reference'),
              children: [
                _buildSectionCard(
                  title: 'LOCAL READINESS',
                  icon: Icons.assessment,
                  child: Column(
                    children: [
                      _buildRow('Average household income',
                          '₹${_numberFormat.format(data.averageHouseholdIncome.round())}'),
                      _buildRow('Daily wage benchmark',
                          '₹${_numberFormat.format(data.wageRate.round())}'),
                      _buildRow('Raw material availability',
                          '${data.rawMaterialAvailability.toStringAsFixed(1)} / 10'),
                      _buildRow('Infrastructure',
                          '${data.infrastructureScore.toStringAsFixed(1)} / 10'),
                      _buildRow('Regional cluster density',
                          data.clusterDensity.toStringAsFixed(1)),
                      _buildRow('Cluster failure rate',
                          '${data.clusterFailureRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                if (data.competitors.isNotEmpty)
                  _buildSectionCard(
                    title: 'NEARBY BUSINESSES',
                    icon: Icons.map,
                    child: Column(
                      children: data.competitors
                          .map(
                            (c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.storefront),
                              title: Text(c.name),
                              trailing: Text(c.distance),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                _buildSectionCard(
                  title: 'DATA SOURCES',
                  icon: Icons.info_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.readableDataSources.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text('${e.key}: ${e.value}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Voice
          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: () => _speak(speechText),
              icon: Icon(_isPlaying ? Icons.stop_circle : Icons.volume_up),
              label: const Text('Listen to Market Summary'),
            ),
          ),
          const SizedBox(height: 24),

          AppButton(
            text: 'Continue to Feasibility',
            onPressed: () {
              Navigator.of(context).pushNamed('/feasibility');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _demandDescription(double score) {
    if (score >= 7) return 'High - many people may need it';
    if (score >= 4) return 'Medium - some people may need it';
    return 'Low - check customer interest first';
  }

  String _opportunityHeadline(MarketModel data) {
    if (data.demandIndex >= 7 && data.competitorCount <= 5) {
      return 'Good opportunity';
    }
    if (data.demandIndex >= 4) return 'Possible opportunity';
    return 'Be careful and check first';
  }

  String _opportunitySummary(MarketModel data) {
    if (data.demandIndex >= 7 && data.competitorCount <= 5) {
      return 'People may need this business and there may be room for a new one.';
    }
    if (data.demandIndex >= 4) {
      return 'Some people may need this business. Visit nearby businesses and ask customers before starting.';
    }
    return 'Customer interest may be limited. Start small and speak with customers before spending money.';
  }

  String _readableValue(String value) {
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
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

  Widget _buildRow(String label, String value) {
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForLevel(String level) {
    final lower = level.toLowerCase();
    if (lower.contains('low') && !lower.contains('opportunity')) {
      return Colors.green; // Low competition = good
    }
    if (lower.contains('low') && lower.contains('opportunity')) {
      return Colors.orange; // Low opportunity = bad
    }
    if (lower.contains('high') && lower.contains('opportunity')) {
      return Colors.green; // High opportunity = good
    }
    if (lower.contains('high') && !lower.contains('opportunity')) {
      return Colors.red; // High competition = bad
    }
    return Colors.blue;
  }
}
