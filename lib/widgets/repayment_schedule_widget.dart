import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_model.dart';

class RepaymentScheduleWidget extends StatelessWidget {
  final List<QuarterlyRepayment> schedule;

  const RepaymentScheduleWidget({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Repayment Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: schedule.map((q) {
          return ListTile(
            title: Text(
              '${q.quarter} ${q.isMoratorium ? '(Moratorium)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Principal: ${currencyFormat.format(q.principal)}'),
                Text('Interest: ${currencyFormat.format(q.interest)}'),
                Text(
                  'Total Installment: ${currencyFormat.format(q.totalInstallment)}',
                ),
                Text(
                  'Closing Balance: ${currencyFormat.format(q.closingBalance)}',
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
