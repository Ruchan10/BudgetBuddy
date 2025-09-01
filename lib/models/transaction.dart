import 'package:flutter/material.dart';

class Transaction {
  final String title;
  final String? description;
  final double amount;
  final DateTime date;
  final String? id;
  Transaction({
    required this.title,
    this.description,
    required this.amount,
    required this.date,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'id': id,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    debugPrint('Transaction from JSON: ${json.toString()}');
    return Transaction(
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      id: json['id'] as String?,
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
