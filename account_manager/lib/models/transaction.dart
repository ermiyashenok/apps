enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String userId; 
  final double amount;
  final DateTime date;
  final TransactionType? _type; // Nullable internally for safety during transitions
  final String category;
  final String comment;
  final DateTime createdAt;

  Transaction({
    required this.id,
    this.userId = 'default_user',
    required this.amount,
    required this.date,
    TransactionType? type, // Allow null here
    required this.category,
    required this.comment,
    DateTime? createdAt,
  }) : _type = type ?? TransactionType.expense, 
       createdAt = createdAt ?? DateTime.now();

  // This getter ensures 'type' is NEVER null for the rest of the app
  TransactionType get type => _type ?? TransactionType.expense;

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.name, 
        'category': category,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      TransactionType type = TransactionType.expense;
      final dynamic typeData = json['type'];
      final dynamic isIncomeData = json['isIncome'];

      if (typeData is String) {
        final String typeStr = typeData.toLowerCase();
        if (typeStr == 'income') {
          type = TransactionType.income;
        } else {
          type = TransactionType.expense;
        }
      } else if (isIncomeData is bool) {
        type = isIncomeData ? TransactionType.income : TransactionType.expense;
      }

      return Transaction(
        id: (json['id'] ?? DateTime.now().toString()).toString(),
        userId: (json['userId'] ?? 'default_user').toString(),
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
        type: type,
        category: (json['category'] ?? 'Other').toString(),
        comment: (json['comment'] ?? '').toString(),
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      );
    } catch (e) {
      return Transaction(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        amount: 0,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: 'Error',
        comment: 'Failed to load transaction',
      );
    }
  }
}
