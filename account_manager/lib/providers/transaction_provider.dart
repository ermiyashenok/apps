import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final List<Transaction> _transactions = [];

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
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }
}
