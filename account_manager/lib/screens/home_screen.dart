import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
//import 'statistics_screen.dart';
import 'consultant_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: txProvider.selectedCurrency, decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
        ),
        title: const Text('Account management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.currency_exchange_rounded),
            tooltip: 'Change Currency',
            onSelected: (String value) async {
              if (value == 'auto') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Detecting location...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                final result = await txProvider.detectCurrencyFromLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } else if (value == 'search') {
                _showCountrySearchDialog(context, txProvider);
              } else {
                txProvider.updateCurrency(value);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: '\$',
                child: Text('USD (\$)'),
              ),
              const PopupMenuItem<String>(
                value: '€',
                child: Text('EUR (€)'),
              ),
              const PopupMenuItem<String>(
                value: '£',
                child: Text('GBP (£)'),
              ),
              const PopupMenuItem<String>(
                value: '¥',
                child: Text('JPY/CNY (¥)'),
              ),
              const PopupMenuItem<String>(
                value: '₹',
                child: Text('INR (₹)'),
              ),
              const PopupMenuItem<String>(
                value: 'Br',
                child: Text('ETB (Br)'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'auto',
                child: Row(
                  children: [
                    Icon(Icons.my_location, size: 18, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Auto Detect'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Search Country'),
                  ],
                ),
              ),
            ],
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
                      border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
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
                          color: Colors.black.withValues(alpha: 0.06),
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
             Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
  child: Row(
    children: [
      Expanded(
        child: Text(
          'Recent Transactions',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
      ),
      InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  },
  borderRadius: BorderRadius.circular(20),
  child: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Icon(Icons.add_rounded, size: 22, color: Theme.of(context).colorScheme.onSecondaryContainer),
  ),
),
    ],
  ),
),
            
            // Minimalistic Transaction List with zero shadows
            Expanded(
              child: txProvider.transactions.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 16),
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
                            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: tx.isIncome 
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : const Color(0xFFF43F5E).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  TransactionProvider.getCategoryIcon(tx.category),
                                  color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          tx.category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (tx.comment.isNotEmpty && tx.comment != 'No comment') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: Colors.black26,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              tx.comment,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: Colors.black.withValues(alpha: 0.4),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateFormat.format(tx.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black.withValues(alpha: 0.3),
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
                                child: Icon(Icons.delete_outline_rounded, color: Colors.black.withValues(alpha: 0.2), size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // Consultant Button at the bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: SizedBox(
                width: 250,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConsultantScreen()),
                    );
                  },
                  icon: const Icon(Icons.psychology_rounded, size: 20),
                  label: const Text(
                    'Get Consultant Advice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
            color: color.withValues(alpha: 0.1),
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
                color: Colors.black.withValues(alpha: 0.5),
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

  void _showCountrySearchDialog(BuildContext context, TransactionProvider txProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return _CountrySearchDialog(txProvider: txProvider);
      },
    );
  }
}

class _CountrySearchDialog extends StatefulWidget {
  final TransactionProvider txProvider;
  const _CountrySearchDialog({required this.txProvider});

  @override
  State<_CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<_CountrySearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final countries = widget.txProvider.searchableCountries;
    final filtered = _query.isEmpty
        ? countries
        : countries.where((c) =>
            c['name']!.toLowerCase().contains(_query.toLowerCase()) ||
            c['code']!.toLowerCase().contains(_query.toLowerCase()) ||
            c['symbol']!.toLowerCase().contains(_query.toLowerCase())
          ).toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Country',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search by country name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Results
          Flexible(
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No countries found', style: TextStyle(color: Colors.black45)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final country = filtered[index];
                      final isSelected = widget.txProvider.selectedCurrency == country['symbol'];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              country['symbol']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isSelected ? Colors.black : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          country['name']!,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          country['code']!,
                          style: const TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.black, size: 20)
                            : null,
                        onTap: () {
                          widget.txProvider.updateCurrency(country['symbol']!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Currency set to ${country['symbol']} (${country['name']})'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
