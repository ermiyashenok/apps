import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
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

    final expenseBreakdown = txProvider.getCategoryBreakdown(isIncome: false);
    final incomeBreakdown = txProvider.getCategoryBreakdown(isIncome: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -1.0)),
        centerTitle: false,
      ),
      body: !hasData 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No transactions to analyze', 
                  style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat('Income', totalIncome, const Color(0xFF10B981), currencyFormat),
                          Container(height: 40, width: 1, color: Colors.black.withOpacity(0.05)),
                          _buildMiniStat('Expense', totalExpense, const Color(0xFFF43F5E), currencyFormat),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Balance',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          Text(
                            currencyFormat.format(totalBalance),
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.w800,
                              color: totalBalance >= 0 ? Colors.black : const Color(0xFFF43F5E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                const Text(
                  'Spending Breakdowns',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 20),
                
                // Expense Category Breakdown Card
                if (expenseBreakdown.isNotEmpty) 
                  _buildBreakdownCard('Expenses', expenseBreakdown, currencyFormat, const Color(0xFFF43F5E)),

                const SizedBox(height: 24),

                // Income Category Breakdown Card
                if (incomeBreakdown.isNotEmpty)
                  _buildBreakdownCard('Income Sources', incomeBreakdown, currencyFormat, const Color(0xFF10B981)),
                
                const SizedBox(height: 32),
                
                // AI Review Section
                const AiReviewSection(),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.4)),
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(String title, Map<String, double> data, NumberFormat format, Color themeColor) {
    final sortedKeys = data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!));
    final total = data.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 24),
          ...sortedKeys.map((category) {
            final amount = data[category]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          TransactionProvider.getCategoryIcon(category),
                          size: 16,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      Text(
                        format.format(amount),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: amount / total,
                      backgroundColor: themeColor.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor.withOpacity(0.7)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
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
