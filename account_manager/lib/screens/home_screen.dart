import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import 'consultant_screen.dart';
import 'profile_screen.dart';
import 'manage_accounts_screen.dart';

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
            // leading: IconButton(...) removed
            title: Text(
              'Dashboard', 
              style: TextStyle(
                color: colorScheme.onSurface, 
                fontSize: 22, 
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              )
            ),
            centerTitle: true,
            actions: [
              _buildAccountSwitcher(context, txProvider),
              _buildCurrencyPicker(context, txProvider, colorScheme, isDark),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ultra Premium Main Balance Carousel
                  _PremiumBalanceCarousel(format: currencyFormat),
                  
                  const SizedBox(height: 32),
                  
                  // Incomes / Expenses Sleek Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildPremiumStatCard(
                            context: context,
                            title: 'Income',
                            amount: txProvider.totalIncome,
                            format: currencyFormat,
                            icon: Icons.arrow_downward_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPremiumStatCard(
                            context: context,
                            title: 'Expense',
                            amount: txProvider.totalExpense,
                            format: currencyFormat,
                            icon: Icons.arrow_upward_rounded,
                            color: const Color(0xFFF43F5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Recent Transactions Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 18, color: colorScheme.onSurface),
                                const SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Transactions List
          if (txProvider.transactions.isEmpty)
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
                      child: Icon(Icons.receipt_long_rounded, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5), 
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = txProvider.transactions[index];
                    return _buildPremiumTransactionTile(context, tx, txProvider, currencyFormat, dateFormat);
                  },
                  childCount: txProvider.transactions.length,
                ),
              ),
            ),
        ],
      ),
      /*
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsultantScreen()),
            );
          },
          backgroundColor: colorScheme.primary,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.psychology_rounded, color: colorScheme.onPrimary, size: 22),
          label: Text(
            'Consultant',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      */
    );
  }



  Widget _buildPremiumStatCard({
    required BuildContext context,
    required String title,
    required double amount,
    required NumberFormat format,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? colorScheme.onSurface.withValues(alpha: 0.05) : Colors.transparent,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            format.format(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTransactionTile(BuildContext context, Transaction tx, TransactionProvider txProvider, NumberFormat format, DateFormat dateFormat) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txColor = tx.isIncome ? const Color(0xFF10B981) : colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? colorScheme.onSurface.withValues(alpha: 0.05) : Colors.transparent,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () => _showDeleteDialog(context, txProvider, tx),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tx.isIncome 
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFFF43F5E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      TransactionProvider.getCategoryIcon(tx.category),
                      color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.category,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (tx.comment.isNotEmpty && tx.comment != 'No comment') ...[
                          const SizedBox(height: 4),
                          Text(
                            tx.comment,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(tx.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tx.isIncome ? '+' : '-'}${format.format(tx.amount)}',
                        style: TextStyle(
                          color: txColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TransactionProvider txProvider, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Transaction?'),
        content: const Text('Are you sure you want to remove this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              txProvider.deleteTransaction(tx.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSwitcher(BuildContext context, TransactionProvider txProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.account_balance_wallet, color: colorScheme.onSurface),
      tooltip: 'Switch Account',
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      onSelected: (String value) {
        if (value == 'manage') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAccountsScreen()));
        } else {
          txProvider.setAccountType(value);
        }
      },
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'All', 
            child: Row(
              children: [
                Icon(Icons.all_inclusive, size: 18, color: txProvider.selectedAccountType == 'All' ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text('All Accounts', style: TextStyle(fontWeight: txProvider.selectedAccountType == 'All' ? FontWeight.bold : FontWeight.normal)),
              ],
            )
          ),
          const PopupMenuDivider(),
        ];
        
        for (final acc in txProvider.accounts) {
          items.add(
            PopupMenuItem<String>(
              value: acc.id, 
              child: Row(
                children: [
                  Icon(Icons.circle, size: 14, color: Color(acc.colorValue)),
                  const SizedBox(width: 8),
                  Text(acc.name, style: TextStyle(fontWeight: txProvider.selectedAccountType == acc.id ? FontWeight.bold : FontWeight.normal)),
                ],
              )
            )
          );
        }
        
        items.add(const PopupMenuDivider());
        items.add(
          PopupMenuItem<String>(
            value: 'manage', 
            child: Row(
              children: [
                Icon(Icons.settings, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                const Text('Manage Accounts'),
              ],
            )
          )
        );
        
        return items;
      },
    );
  }

  Widget _buildCurrencyPicker(BuildContext context, TransactionProvider txProvider, ColorScheme colorScheme, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.currency_exchange_rounded, color: colorScheme.onSurface),
      tooltip: 'Change Currency',
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
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
                      fontWeight: FontWeight.w800,
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
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          country['name']!,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

class _PremiumBalanceCarousel extends StatefulWidget {
  final NumberFormat format;
  const _PremiumBalanceCarousel({required this.format});

  @override
  State<_PremiumBalanceCarousel> createState() => _PremiumBalanceCarouselState();
}

class _PremiumBalanceCarouselState extends State<_PremiumBalanceCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);
    final accountsList = ['All', ...txProvider.accounts.map((a) => a.id)];
    
    int currentIndex = accountsList.indexOf(txProvider.selectedAccountType);
    if (currentIndex == -1) currentIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _pageController.page?.round() != currentIndex) {
        _pageController.animateToPage(currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });

    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          txProvider.setAccountType(accountsList[index]);
        },
        itemCount: accountsList.length,
        itemBuilder: (context, index) {
          final accId = accountsList[index];
          final balance = txProvider.getBalanceForAccount(accId);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildCard(context, txProvider, accId, balance),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, TransactionProvider txProvider, String accId, double balance) {
    List<Color> gradientColors;
    String accountName;
    
    if (accId == 'All') {
      gradientColors = [const Color(0xFF27272A), const Color(0xFF18181B)];
      accountName = 'All Accounts';
    } else {
      final account = txProvider.accounts.firstWhere(
        (a) => a.id == accId, 
        orElse: () => txProvider.accounts.first
      );
      final c = Color(account.colorValue);
      gradientColors = [c, c.withValues(alpha: 0.8)];
      accountName = account.name;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        accId == 'All' ? 'Total Balance' : '$accountName Balance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white.withValues(alpha: 0.7), size: 24),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  widget.format.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accId == 'All' 
                    ? 'Available across all accounts'
                    : 'Available in $accountName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
