import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];

  TransactionProvider() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsString = prefs.getString('transactions');
    if (transactionsString != null) {
      final List<dynamic> jsonList = json.decode(transactionsString);
      _transactions = jsonList.map((jsonItem) => Transaction.fromJson(jsonItem)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String transactionsString = json.encode(
      _transactions.map((tx) => tx.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsString);
  }

  List<Transaction> get transactions {
    // Return a sorted list, newest first
    var sortedList = [..._transactions];
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }

  double get totalBalance {
    return totalIncome - totalExpense;
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => !tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  List<Transaction> getTransactionsForDay(DateTime day) {
    return _transactions.where((tx) {
      return tx.date.year == day.year &&
             tx.date.month == day.month &&
             tx.date.day == day.day;
    }).toList();
  }

  double getDailyIncome(DateTime day) {
    return getTransactionsForDay(day)
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getDailyExpense(DateTime day) {
    return getTransactionsForDay(day)
        .where((tx) => !tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    _saveTransactions();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    _saveTransactions();
    notifyListeners();
  }
}
