import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../providers/transaction_provider.dart';
import '../services/chat_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isExpenses = true;

  void _showAccountPicker(BuildContext context, TransactionProvider txProvider) {
    final accounts = ['All', ...txProvider.accounts.map((a) => a.id)];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: accounts.map((accId) {
              final isSelected = txProvider.selectedAccountType == accId;
              final accName = accId == 'All' 
                  ? 'All accounts' 
                  : txProvider.accounts.firstWhere((a) => a.id == accId).name;
              
              return ListTile(
                title: Text(accName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF3B82F6)) : null,
                onTap: () {
                  txProvider.setAccountType(accId);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: txProvider.selectedCurrency, 
      decimalDigits: 0,
    );
    
    final breakdown = txProvider.getCategoryBreakdown(isIncome: !_isExpenses);
    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    final hasData = total > 0;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortedKeys = breakdown.keys.toList()..sort((a, b) => breakdown[b]!.compareTo(breakdown[a]!));

    final chartColors = [
      const Color(0xFF3B82F6), // blue
      const Color(0xFFF97316), // orange
      const Color(0xFF10B981), // green
      const Color(0xFF8B5CF6), // purple
      const Color(0xFFF43F5E), // red
      const Color(0xFFEAB308), // yellow
      const Color(0xFF06B6D4), // cyan
      const Color(0xFF9CA3AF), // grey
    ];

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
            title: GestureDetector(
              onTap: () => _showAccountPicker(context, txProvider),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    txProvider.selectedAccountType == 'All' 
                        ? 'Statistics (All cards)' 
                        : 'Statistics (${txProvider.selectedAccountType})',
                    style: TextStyle(
                      color: colorScheme.onSurface, 
                      fontWeight: FontWeight.w800, 
                      fontSize: 20, 
                      letterSpacing: -0.5
                    )
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurface, size: 24),
                ],
              ),
            ),
            centerTitle: true,
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Toggle Expenses / Income
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isExpenses = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isExpenses ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Expenses', style: TextStyle(
                              color: _isExpenses ? (isDark ? Colors.black : Colors.white) : colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: _isExpenses ? FontWeight.bold : FontWeight.w500,
                            )),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isExpenses = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isExpenses ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('Income', style: TextStyle(
                              color: !_isExpenses ? (isDark ? Colors.black : Colors.white) : colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: !_isExpenses ? FontWeight.bold : FontWeight.w500,
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Donut Chart
                  if (!hasData)
                    Container(
                      height: 240,
                      alignment: Alignment.center,
                      child: Text('No data available.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
                    )
                  else
                    SizedBox(
                      height: 240,
                      width: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(240, 240),
                            painter: DonutChartPainter(breakdown, total, chartColors),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormat.format(total),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Legend Grid
                  if (hasData)
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(sortedKeys.length, (index) {
                        final cat = sortedKeys[index];
                        final amount = breakdown[cat]!;
                        final color = chartColors[index % chartColors.length];
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width - 48 - 16) / 2,
                          child: Row(
                            children: [
                              Container(
                                width: 14, 
                                height: 14, 
                                decoration: BoxDecoration(
                                  color: color, 
                                  shape: BoxShape.circle
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat, 
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                currencyFormat.format(amount), 
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                )
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                  const SizedBox(height: 48),
                  
                  // AI Review Section
                  // const AiReviewSection(), // Temporarily commented out until API integration
                  
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;
  final List<Color> colors;

  DonutChartPainter(this.data, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    
    double startAngle = -math.pi / 2;
    
    int colorIndex = 0;
    for (var entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final gap = 0.15; // gap between segments
      if (sweepAngle > gap) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle + gap/2,
          sweepAngle - gap,
          false,
          paint,
        );
      } else {
         canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
      startAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
