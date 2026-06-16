import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
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

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Colors.transparent),
              ),
            ),
            title: Text(
              'Insights', 
              style: TextStyle(
                color: colorScheme.onSurface, 
                fontWeight: FontWeight.w800, 
                fontSize: 24, 
                letterSpacing: -1.0
              )
            ),
            centerTitle: false,
          ),
          
          if (!hasData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.analytics_outlined, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No transactions to analyze', 
                      style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Section
                    _buildPremiumSummaryCard(context, totalIncome, totalExpense, totalBalance, currencyFormat),
                    
                    const SizedBox(height: 40),
                    Text(
                      'Spending Breakdowns',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 24),
                    
                    // Expense Category Breakdown Card
                    if (expenseBreakdown.isNotEmpty) 
                      _buildBreakdownCard('Expenses', expenseBreakdown, currencyFormat, const Color(0xFFF43F5E), context),

                    if (expenseBreakdown.isNotEmpty) const SizedBox(height: 24),

                    // Income Category Breakdown Card
                    if (incomeBreakdown.isNotEmpty)
                      _buildBreakdownCard('Income Sources', incomeBreakdown, currencyFormat, const Color(0xFF10B981), context),
                    
                    if (incomeBreakdown.isNotEmpty) const SizedBox(height: 40),
                    
                    // AI Review Section
                    const AiReviewSection(),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumSummaryCard(BuildContext context, double income, double expense, double balance, NumberFormat format) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? colorScheme.onSurface.withValues(alpha: 0.05) : Colors.transparent,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildMiniStat('Income', income, const Color(0xFF10B981), format, context),
              ),
              Container(height: 56, width: 1, color: colorScheme.onSurface.withValues(alpha: 0.08)),
              Expanded(
                child: _buildMiniStat('Expense', expense, const Color(0xFFF43F5E), format, context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Balance',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    format.format(balance),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w800,
                      color: balance >= 0 ? colorScheme.onSurface : const Color(0xFFF43F5E),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color, NumberFormat format, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 8),
        Text(
          format.format(amount),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(String title, Map<String, double> data, NumberFormat format, Color themeColor, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedKeys = data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!));
    final total = data.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? colorScheme.onSurface.withValues(alpha: 0.05) : Colors.transparent,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.03),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.2),
          ),
          const SizedBox(height: 32),
          ...sortedKeys.map((category) {
            final amount = data[category]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          TransactionProvider.getCategoryIcon(category),
                          size: 20,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colorScheme.onSurface),
                        ),
                      ),
                      Text(
                        format.format(amount),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorScheme.onSurface, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: amount / total,
                      backgroundColor: themeColor.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor.withValues(alpha: 0.8)),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [colorScheme.secondary.withValues(alpha: 0.8), colorScheme.primary.withValues(alpha: 0.8)]
              : [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'AI Financial Insights',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (_review != null && !_isLoading)
                IconButton(
                  onPressed: _generateReview,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                  tooltip: 'Regenerate',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            )
          else if (_review != null)
            Text(
              _review!,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                height: 1.6,
                fontWeight: FontWeight.w500
              ),
            )
          else if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.w500),
            )
          else
            Text(
              "Get a personalized review of your spending habits and saving tips from our AI Advisor.",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
            ),
          
          if (_review == null && !_isLoading) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  'Generate Review', 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
