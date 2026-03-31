class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String comment;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.comment,
  });
}
