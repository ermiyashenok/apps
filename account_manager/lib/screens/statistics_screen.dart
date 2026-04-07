import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../services/chat_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: txProvider.selectedCurrency, 
      decimalDigits: 2,
    );
    
    final totalIncome = txProvider.totalIncome;
    final totalExpense = txProvider.totalExpense;
    final totalBalance = txProvider.totalBalance;
    final hasData = totalIncome > 0 || totalExpense > 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financial Stats', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: !hasData 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No data to show yet', 
                  style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Section
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Balance', 
                        currencyFormat.format(totalBalance), 
                        totalBalance >= 0 ? Colors.blue[700]! : Colors.orange[700]!,
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Income', 
                        currencyFormat.format(totalIncome), 
                        Colors.teal[600]!,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Expense', 
                        currencyFormat.format(totalExpense), 
                        Colors.redAccent[400]!,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'Spending Breakdowns',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // Chart Section
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 5,
                          centerSpaceRadius: 70,
                          startDegreeOffset: -90,
                          sections: [
                            if (totalIncome > 0)
                              PieChartSectionData(
                                color: Colors.teal[600],
                                value: totalIncome,
                                title: '',
                                radius: 25,
                              ),
                            if (totalExpense > 0)
                              PieChartSectionData(
                                color: Colors.redAccent[400],
                                value: totalExpense,
                                title: '',
                                radius: 25,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Net',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          Text(
                            currencyFormat.format(totalBalance),
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                // Custom Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Income', Colors.teal[600]!),
                    const SizedBox(width: 24),
                    _buildLegendItem('Expense', Colors.redAccent[400]!),
                  ],
                ),

                const SizedBox(height: 40),
                
                // AI Review Section
                const AiReviewSection(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title, 
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount, 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: color.darken(0.1) // Placeholder for color tweak if needed
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}

// Extension to darken colors slightly for text
extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class AiReviewSection extends StatefulWidget {
  const AiReviewSection({super.key});

  @override
  State<AiReviewSection> createState() => _AiReviewSectionState();
}

class _AiReviewSectionState extends State<AiReviewSection> {
  String? _review;
  bool _isLoading = false;
  String? _error;

  Future<void> _generateReview() async {
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final review = await ChatService.getFinancialReview(
        transactions: txProvider.transactions,
        totalBalance: txProvider.totalBalance,
        totalIncome: txProvider.totalIncome,
        totalExpense: txProvider.totalExpense,
        currency: txProvider.selectedCurrency,
      );
      
      if (mounted) {
        setState(() {
          _review = review;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Couldn't get AI review. Check your connection.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[400]!, Colors.purple[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'AI Financial Insights',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const Spacer(),
              if (_review != null && !_isLoading)
                IconButton(
                  onPressed: _generateReview,
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  tooltip: 'Regenerate',
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else if (_review != null)
            Text(
              _review!,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 15, 
                height: 1.5,
                fontWeight: FontWeight.w400
              ),
            )
          else if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            )
          else
            const Text(
              "Get a personalized review of your spending habits and saving tips from our AI Advisor.",
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          
          if (_review == null && !_isLoading) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Generate Review', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
