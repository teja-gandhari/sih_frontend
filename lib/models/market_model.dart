class MarketModel {
  final String applicationId;
  final double demandIndex;
  final int competitorCount;
  final double wageRate;
  final double averageHouseholdIncome;
  final String competitionLevel;
  final double rawMaterialAvailability;
  final double infrastructureScore;
  final double clusterDensity;
  final double clusterFailureRate;
  final String opportunityClassification;
  final String opportunityExplanation;
  final String? purchasingPower;
  final String? seasonality;
  final List<String> harvestMonths;
  final double? mandiDistanceKm;
  final String dataConfidence;
  final List<Competitor> competitors;
  final Map<String, String> dataSources;

  String get readableOpportunityExplanation {
    final raw = opportunityExplanation.trim();
    if (raw.isEmpty) {
      return 'No live market record was found for this area. We used conservative planning estimates to help you proceed carefully.';
    }

    String cleaned = raw
        .replaceAll(RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'), 'this location')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = cleaned.toLowerCase();
    if (lower.contains('no live market record was found') ||
        lower.contains('using conservative') ||
        lower.contains('proxy-based estimate') ||
        lower.contains('low_proxy')) {
      cleaned = cleaned
          .replaceAll('low_proxy', 'proxy-based estimate')
          .replaceAll('LOW_PROXY', 'proxy-based estimate');
      cleaned = cleaned.replaceAll('proxy indicators', 'proxy indicators');
      return cleaned;
    }

    if (lower.contains('demand index')) {
      return 'Market demand appears limited in this area. We used conservative planning estimates because live market data is not available.';
    }

    return cleaned;
  }

  Map<String, String> get readableDataSources {
    final normalized = <String, String>{};
    for (final entry in dataSources.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (key.isEmpty) continue;

      String readableValue = value
          .replaceAll(
            RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'),
            'location-based estimate',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (readableValue.toLowerCase().contains('low_proxy')) {
        readableValue = readableValue.replaceAll('low_proxy', 'proxy-based estimate');
      }

      if (readableValue.toLowerCase().contains('proxy indicators')) {
        readableValue = readableValue.replaceAll('proxy indicators', 'proxy indicators');
      }

      normalized[key] = readableValue.isNotEmpty ? readableValue : 'Local market estimate';
    }
    return normalized;
  }

  MarketModel({
    required this.applicationId,
    required this.demandIndex,
    required this.competitorCount,
    required this.wageRate,
    required this.averageHouseholdIncome,
    required this.competitionLevel,
    required this.rawMaterialAvailability,
    required this.infrastructureScore,
    required this.clusterDensity,
    required this.clusterFailureRate,
    required this.opportunityClassification,
    required this.opportunityExplanation,
    this.purchasingPower,
    this.seasonality,
    required this.harvestMonths,
    this.mandiDistanceKm,
    required this.dataConfidence,
    required this.competitors,
    required this.dataSources,
  });

  factory MarketModel.fromJson(String appId, Map<String, dynamic> json) {
    final formal = (json['formal_competitor_count'] as num?)?.toInt() ?? 0;
    final informal = (json['estimated_informal_competitor_count'] as num?)?.toInt() ?? 0;
    final demand = (json['demand_index'] as num?)?.toDouble() ?? 0;
    final confidence = json['data_confidence_level']?.toString() ?? 'unknown';
    return MarketModel(
      applicationId: appId,
      demandIndex: demand,
      competitorCount: formal + informal,
      wageRate: (json['mgnrega_daily_wage_rate'] as num?)?.toDouble() ?? 0,
      averageHouseholdIncome:
          (json['average_monthly_household_income'] as num?)?.toDouble() ?? 0,
      competitionLevel: informal > formal ? 'Informal competition is significant' : 'Formal competition is significant',
      rawMaterialAvailability:
          (json['raw_material_availability_score'] as num?)?.toDouble() ?? 0,
      infrastructureScore:
          (json['infrastructure_score'] as num?)?.toDouble() ?? 0,
      clusterDensity:
          (json['regional_cluster_density_25km'] as num?)?.toDouble() ?? 0,
      clusterFailureRate:
          (json['regional_cluster_failure_rate_pct'] as num?)?.toDouble() ?? 0,
      opportunityClassification: demand >= 7 ? 'Market opportunity' : 'Proceed with caution',
      opportunityExplanation: json['notes']?.toString() ?? 'Demand index: $demand/10.',
      purchasingPower: json['purchasing_power_tier']?.toString(),
      seasonality: json['seasonal_dependence']?.toString(),
      harvestMonths: (json['harvest_months'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      mandiDistanceKm:
          (json['nearest_mandi_distance_km'] as num?)?.toDouble(),
      dataConfidence: confidence,
      competitors: const [],
      dataSources: {'Market data': confidence},
    );
  }
}

class Competitor {
  final String name;
  final String distance;

  Competitor({required this.name, required this.distance});

  factory Competitor.fromJson(Map<String, dynamic> json) {
    return Competitor(
      name: json['name']?.toString() ?? '',
      distance: json['distance']?.toString() ?? '',
    );
  }
}
