import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: txProvider.selectedCurrency, decimalDigits: 2);
    
    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;
    final hasData = totalIncome > 0 || totalExpense > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: !hasData 
        ? const Center(child: Text('No data to display statistics.', style: TextStyle(fontSize: 18)))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Income vs Expenses',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: [
                        if (totalIncome > 0)
                          PieChartSectionData(
                            color: Colors.green,
                            value: totalIncome,
                            title: '${(totalIncome / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        if (totalExpense > 0)
                          PieChartSectionData(
                            color: Colors.redAccent,
                            value: totalExpense,
                            title: '${(totalExpense / (totalIncome + totalExpense) * 100).toStringAsFixed(1)}%',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Income', Colors.green, currencyFormat.format(totalIncome)),
                    _buildLegendItem('Expense', Colors.redAccent, currencyFormat.format(totalExpense)),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLegendItem(String title, Color color, String amount) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 16, height: 16, color: color, margin: const EdgeInsets.only(right: 8)),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }
}
