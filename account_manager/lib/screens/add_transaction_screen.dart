import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isIncome = false;
  String _selectedCategory = 'Other';

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final newTx = Transaction(
      id: DateTime.now().toString(),
      amount: enteredAmount,
      date: DateTime.now(),
      type: _isIncome ? TransactionType.income : TransactionType.expense,
      comment: _commentController.text.isEmpty ? 'No comment' : _commentController.text,
      category: _selectedCategory,
    );

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(newTx);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = Provider.of<TransactionProvider>(context, listen: false).selectedCurrency;
    final categories = _isIncome 
        ? TransactionProvider.incomeCategories 
        : TransactionProvider.expenseCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('New Entry'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Amount Input Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Text(
                    _isIncome ? 'HOW MUCH DID YOU RECEIVE?' : 'HOW MUCH DID YOU SPEND?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[400],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currencySymbol,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -2,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Color(0xFFE5E7EB)),
                          ),
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Selector
                  Row(
                    children: [
                      _buildTypeButton('Expense', !_isIncome, const Color(0xFFEF4444)),
                      const SizedBox(width: 12),
                      _buildTypeButton('Income', _isIncome, const Color(0xFF10B981)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Category Section
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['name'];
                          });
                        },
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.secondaryContainer
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.secondary
                                      : const Color(0xFFE5E7EB),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                cat['icon'],
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.secondary
                                    : const Color(0xFF6B7280),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.secondary
                                    : const Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Comment Section
                  const Text(
                    'Add Note',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'What was this for?',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Confirm Transaction',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isIncome = (label == 'Income');
            // Reset category to first available in the new list
            _selectedCategory = _isIncome 
                ? TransactionProvider.incomeCategories.first['name']
                : TransactionProvider.expenseCategories.first['name'];
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == 'Income' ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isSelected ? color : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
