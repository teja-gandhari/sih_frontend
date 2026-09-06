class FeasibilityModel {
  final String applicationId;
  final int overallScore;
  final String viabilityRating;
  final String explanation;
  final int financialScore;
  final int marketScore;
  final int schemeScore;
  final int riskScore;
  final Map<String, int> scoreWeights;
  final String? marketGap;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> opportunities;
  final List<String> threats;
  final List<String> riskWarnings;
  final List<String> recommendations;
  final String dataConfidence;

  FeasibilityModel({
    required this.applicationId,
    required this.overallScore,
    required this.viabilityRating,
    required this.explanation,
    required this.financialScore,
    required this.marketScore,
    required this.schemeScore,
    required this.riskScore,
    required this.scoreWeights,
    this.marketGap,
    required this.strengths,
    required this.weaknesses,
    required this.opportunities,
    required this.threats,
    required this.riskWarnings,
    required this.recommendations,
    required this.dataConfidence,
  });

  factory FeasibilityModel.fromJson(String appId, Map<String, dynamic> json) {
    int score(String key) => ((json[key] as num?)?.round() ?? 0);
    final swot = Map<String, dynamic>.from(json['swot_analysis'] ?? {});
    List<String> items(Map<String, dynamic> source, String key) =>
        (source[key] as List?)?.map((e) => e.toString()).toList() ?? [];
    final keyRecommendations =
        (json['key_recommendations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final riskWarnings = <String>[];
    final informalWarning = json['informal_competition_warning'];
    final seasonalWarning = json['seasonal_cashflow_warning'];
    if (informalWarning != null && informalWarning.toString().isNotEmpty) {
      riskWarnings.add(informalWarning.toString());
    }
    if (seasonalWarning != null && seasonalWarning.toString().isNotEmpty) {
      riskWarnings.add(seasonalWarning.toString());
    }

    return FeasibilityModel(
      applicationId: appId,
      overallScore: score('overall_score'),
      viabilityRating: json['viability_rating']?.toString() ?? 'UNKNOWN',
      explanation: keyRecommendations.isNotEmpty
          ? keyRecommendations.join(' ')
          : (json['localized_advisory'] is Map
                ? json['localized_advisory']['en']?.toString() ?? ''
                : ''),
      financialScore: score('financial_viability_score'),
      marketScore: score('market_demand_score'),
      schemeScore: score('resource_readiness_score'),
      riskScore: score('risk_score'),
      scoreWeights: const {},
      marketGap: json['market_gap_classification']?.toString(),
      strengths: items(swot, 'strengths'),
      weaknesses: items(swot, 'weaknesses'),
      opportunities: items(swot, 'opportunities'),
      threats: items(swot, 'threats'),
      riskWarnings: riskWarnings,
      recommendations: keyRecommendations,
      dataConfidence: json['data_confidence_level']?.toString() ?? 'Unknown',
    );
  }
}
