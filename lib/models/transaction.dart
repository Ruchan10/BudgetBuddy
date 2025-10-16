import 'package:budgget_buddy/models/category.dart';
import 'package:flutter/material.dart';

class Transaction {
  final String title;
  final Category? category;
  final double amount;
  final DateTime date;
  final String? id;

  Transaction({
    required this.title,
    this.category,
    required this.amount,
    required this.date,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'id': id,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    debugPrint('Transaction from JSON: ${json.toString()}');
    return Transaction(
      title: json['title'] as String,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      id: json['id'] as String?,
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    Category? category,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
