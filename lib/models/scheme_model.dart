class SchemeModel {
  final String applicationId;
  final String schemeName;
  final String schemeCode;
  final bool isEligible;
  final String reason;
  final double projectCost;
  final double marginContribution;
  final double maximumLoanAmount;
  final double interestRate;
  final int tenure;
  final int moratorium;
  final double marginPercentage;
  final List<String> benefits;
  final List<String> warnings;

  SchemeModel({
    required this.applicationId,
    required this.schemeName,
    required this.schemeCode,
    required this.isEligible,
    required this.reason,
    required this.projectCost,
    required this.marginContribution,
    required this.maximumLoanAmount,
    required this.interestRate,
    required this.tenure,
    required this.moratorium,
    required this.marginPercentage,
    required this.benefits,
    required this.warnings,
  });

  factory SchemeModel.fromJson(String appId, dynamic json) {
    final payload = json is List
        ? (json.isNotEmpty
              ? Map<String, dynamic>.from(json.first ?? {})
              : <String, dynamic>{})
        : Map<String, dynamic>.from(json ?? const {});

    double number(String key) => (payload[key] as num?)?.toDouble() ?? 0;
    final schemeCode =
        payload['scheme_code']?.toString() ??
        payload['matched_scheme_code']?.toString() ??
        '';
    final schemeName = payload['scheme_name']?.toString() ?? schemeCode;
    final eligible = payload['eligible'] == true || schemeCode.isNotEmpty;
    final reasons =
        (payload['reasons'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final benefits =
        (payload['benefits'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    final warnings =
        (payload['warnings'] as List?)?.map((e) => e.toString()).toList() ??
        const [];

    final projectCost =
        number('project_cost') != 0
            ? number('project_cost')
            : (number('total_project_cost') != 0
                ? number('total_project_cost')
                : number('project_cost_derived'));
    final marginContribution =
        number('margin_required_amount') != 0
            ? number('margin_required_amount')
            : number('user_margin_amount');
    final maximumLoanAmount =
        number('net_bank_loan') != 0
            ? number('net_bank_loan')
            : (number('net_bank_loan_required') != 0
                ? number('net_bank_loan_required')
                : 0.0);
    final interestRate =
        number('estimated_interest_rate') != 0
            ? number('estimated_interest_rate')
            : number('annual_interest_rate');
    final tenureMonths =
        ((payload['tenure_months'] as num?)?.toInt() ??
            ((payload['loan_tenure_months'] as num?)?.toInt() ??
                ((payload['max_tenure_months'] as num?)?.toInt() ?? 0)));
    final moratoriumMonths =
        (payload['moratorium_months'] as num?)?.toInt() ?? 0;

    return SchemeModel(
      applicationId: appId,
      schemeName: schemeName,
      schemeCode: schemeCode,
      isEligible: eligible,
      reason: reasons.isNotEmpty
          ? reasons.join(' ')
          : (eligible
                ? 'Eligible based on project profile and sector.'
                : 'No matching scheme was found.'),
      projectCost: projectCost,
      marginContribution: marginContribution,
      maximumLoanAmount: maximumLoanAmount,
      interestRate: interestRate,
      tenure: tenureMonths > 0 ? tenureMonths ~/ 12 : 0,
      moratorium: moratoriumMonths,
      marginPercentage: number('margin_required_percentage') != 0
          ? number('margin_required_percentage')
          : number('user_margin_pct'),
      benefits: benefits.isNotEmpty
          ? benefits
          : (eligible
                ? [
                    'Subsidy eligible: ₹${number('subsidy_amount').toStringAsFixed(0)}',
                  ]
                : const []),
      warnings: warnings,
    );
  }
}
