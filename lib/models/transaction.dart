class Transaction {
  final String description;
  final String? subDesc;
  final double amount;
  final DateTime date;

  Transaction({
    required this.description,
    this.subDesc,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'subDesc': subDesc,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      description: json['description'] as String,
      subDesc: json['subDesc'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
