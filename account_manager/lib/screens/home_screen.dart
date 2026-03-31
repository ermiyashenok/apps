import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Premium Unified Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(txProvider.totalBalance),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Incomes / Expenses Pill Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            icon: Icons.arrow_downward_rounded,
                            color: const Color(0xFF10B981),
                            label: 'Income',
                            amount: txProvider.totalIncome,
                            format: currencyFormat,
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.black.withOpacity(0.06),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: _buildMiniStat(
                              icon: Icons.arrow_upward_rounded,
                              color: const Color(0xFFF43F5E),
                              label: 'Expense',
                              amount: txProvider.totalExpense,
                              format: currencyFormat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Transactions Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            
            // Minimalistic Transaction List with zero shadows
            Expanded(
              child: txProvider.transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: txProvider.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = txProvider.transactions[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: tx.isIncome 
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : const Color(0xFFF43F5E).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  tx.isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                                  color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.comment,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(tx.date),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: tx.isIncome ? const Color(0xFF10B981) : Colors.black,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => txProvider.deleteTransaction(tx.id),
                                child: Icon(Icons.delete_outline_rounded, color: Colors.black.withOpacity(0.2), size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
    required NumberFormat format,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              format.format(amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
