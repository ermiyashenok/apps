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

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
        'comment': comment,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        isIncome: json['isIncome'],
        comment: json['comment'],
      );
}
