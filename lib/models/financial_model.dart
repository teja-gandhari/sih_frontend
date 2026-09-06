class FinancialModel {
  final String applicationId;
  final double availableMarginCapital;
  final double totalFeasibleProjectCost;
  final double maximumLoanAmount;
  final String selectedSchemeTier;
  final double interestRate;
  final int tenure;
  final int moratorium;
  final double monthlyEmi;
  final double quarterlyInstallment;
  final List<QuarterlyRepayment> repaymentSchedule;

  FinancialModel({
    required this.applicationId,
    required this.availableMarginCapital,
    required this.totalFeasibleProjectCost,
    required this.maximumLoanAmount,
    required this.selectedSchemeTier,
    required this.interestRate,
    required this.tenure,
    required this.moratorium,
    required this.monthlyEmi,
    required this.quarterlyInstallment,
    required this.repaymentSchedule,
  });

  factory FinancialModel.fromJson(String appId, Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final monthlyEmi = number('monthly_emi_amount');
    return FinancialModel(
      applicationId: appId,
      availableMarginCapital: number('user_margin_amount'),
      totalFeasibleProjectCost: number('total_project_cost'),
      maximumLoanAmount: number('net_bank_loan_required'),
      selectedSchemeTier: json['matched_scheme_code']?.toString() ?? '',
      interestRate: number('annual_interest_rate'),
      tenure: ((json['loan_tenure_months'] as num?)?.toInt() ?? 0) ~/ 12,
      moratorium: 0,
      monthlyEmi: monthlyEmi,
      quarterlyInstallment: monthlyEmi * 3,
      repaymentSchedule: (json['quarterly_repayment_schedule'] as List?)
              ?.map((e) => QuarterlyRepayment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class QuarterlyRepayment {
  final String quarter;
  final bool isMoratorium;
  final double principal;
  final double interest;
  final double totalInstallment;
  final double closingBalance;

  QuarterlyRepayment({
    required this.quarter,
    required this.isMoratorium,
    required this.principal,
    required this.interest,
    required this.totalInstallment,
    required this.closingBalance,
  });

  factory QuarterlyRepayment.fromJson(Map<String, dynamic> json) {
    return QuarterlyRepayment(
      quarter: json['quarter']?.toString() ?? '',
      isMoratorium: json['is_moratorium'] ?? false,
      principal: (json['principal'] ?? 0).toDouble(),
      interest: (json['interest'] ?? 0).toDouble(),
      totalInstallment: (json['total_installment'] ?? 0).toDouble(),
      closingBalance: (json['closing_balance'] ?? 0).toDouble(),
    );
  }
}
