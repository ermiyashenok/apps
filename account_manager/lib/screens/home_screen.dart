import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'consultant_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: txProvider.selectedCurrency, decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
        ),
        title: Text('Account Management', style: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.currency_exchange_rounded, color: colorScheme.onSurface),
            tooltip: 'Change Currency',
            color: colorScheme.surface,
            onSelected: (String value) async {
              if (value == 'auto') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Detecting location...'), duration: Duration(seconds: 1)),
                );
                final result = await txProvider.detectCurrencyFromLocation();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result), duration: const Duration(seconds: 3)),
                  );
                }
              } else if (value == 'search') {
                _showCountrySearchDialog(context, txProvider);
              } else {
                txProvider.updateCurrency(value);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: '\$', child: Text('USD (\$)')),
              const PopupMenuItem<String>(value: '€', child: Text('EUR (€)')),
              const PopupMenuItem<String>(value: '£', child: Text('GBP (£)')),
              const PopupMenuItem<String>(value: '¥', child: Text('JPY/CNY (¥)')),
              const PopupMenuItem<String>(value: '₹', child: Text('INR (₹)')),
              const PopupMenuItem<String>(value: 'Br', child: Text('ETB (Br)')),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'auto',
                child: Row(
                  children: [
                    Icon(Icons.my_location, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    const Text('Auto Detect'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    const Text('Search Country'),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(txProvider.totalBalance),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Incomes / Expenses Pill Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : colorScheme.primary.withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
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
                            context: context,
                          ),
                        ),
                        Container(
                          height: 48,
                          width: 1,
                          color: colorScheme.onSurface.withValues(alpha: 0.1),
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
                              context: context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Recent Transactions Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.add_rounded, size: 24, color: colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
            
            // Minimalistic Transaction List
            Expanded(
              child: txProvider.transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: txProvider.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = txProvider.transactions[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black12 : colorScheme.primary.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: tx.isIncome 
                                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                      : const Color(0xFFF43F5E).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  TransactionProvider.getCategoryIcon(tx.category),
                                  color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                                  size: 24,
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        if (tx.comment.isNotEmpty && tx.comment != 'No comment') ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: colorScheme.onSurface.withValues(alpha: 0.3),
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
                                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dateFormat.format(tx.date),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                style: TextStyle(
                                  color: tx.isIncome ? const Color(0xFF10B981) : colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => txProvider.deleteTransaction(tx.id),
                                icon: Icon(Icons.delete_outline_rounded, color: colorScheme.onSurface.withValues(alpha: 0.2), size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            
            // Consultant Button at the bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConsultantScreen()),
                    );
                  },
                  icon: const Icon(Icons.psychology_rounded, size: 22),
                  label: const Text(
                    'Get Consultant Advice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
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
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              format.format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countries = widget.txProvider.searchableCountries;
    final filtered = _query.isEmpty
        ? countries
        : countries.where((c) =>
            c['name']!.toLowerCase().contains(_query.toLowerCase()) ||
            c['code']!.toLowerCase().contains(_query.toLowerCase()) ||
            c['symbol']!.toLowerCase().contains(_query.toLowerCase())
          ).toList();

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Search Country',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              autofocus: true,
              style: TextStyle(color: colorScheme.onSurface),
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Search by country name...',
                hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: isDark ? colorScheme.onSurface.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Results
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No countries found', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final country = filtered[index];
                      final isSelected = widget.txProvider.selectedCurrency == country['symbol'];
                      return ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : (isDark ? colorScheme.onSurface.withValues(alpha: 0.05) : Colors.grey.shade100),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              country['symbol']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          country['name']!,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          country['code']!,
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: colorScheme.primary, size: 22)
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
