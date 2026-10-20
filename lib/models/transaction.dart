import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// Default for nullable copyWith parameters, so passing null can clear a value.
const Object _keep = Object();

class Transaction {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final DateTime date;
  final String? category;

  /// When this record was last changed on any device. Sync keeps the newest copy.
  final DateTime updatedAt;

  /// Soft-delete marker, kept until the deletion has reached Supabase.
  final bool deleted;

  /// True while this version still has to be uploaded to Supabase.
  final bool pendingSync;

  Transaction({
    String? id,
    required this.title,
    this.description,
    required this.amount,
    required this.date,
    this.category,
    DateTime? updatedAt,
    this.deleted = false,
    this.pendingSync = true,
  }) : id = id ?? _uuid.v4(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'id': id,
    'category': category,
    // UTC so a change of time zone can't reorder edits.
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'deleted': deleted,
    'pendingSync': pendingSync,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final updatedAt = json['updatedAt'] as String?;
    return Transaction(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: date,
      category: json['category'] as String?,
      // Entries saved before sync existed have no edit time; their date is the best guess.
      updatedAt: updatedAt == null ? date : DateTime.parse(updatedAt),
      deleted: json['deleted'] as bool? ?? false,
      pendingSync: json['pendingSync'] as bool? ?? true,
    );
  }

  /// Row for the `transactions` table in Supabase (see supabase/setup.sql).
  Map<String, dynamic> toRemote() => {
    'id': id,
    'title': title,
    'description': description,
    'amount': amount,
    'category': category,
    'occurred_at': date.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted': deleted,
  };

  factory Transaction.fromRemote(Map<String, dynamic> row) => Transaction(
    id: row['id'] as String,
    title: row['title'] as String,
    description: row['description'] as String?,
    amount: _toDouble(row['amount']),
    date: DateTime.parse(row['occurred_at'] as String).toLocal(),
    category: row['category'] as String?,
    updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
    deleted: row['deleted'] as bool? ?? false,
    pendingSync: false,
  );

  Transaction copyWith({
    String? title,
    Object? description = _keep,
    double? amount,
    DateTime? date,
    Object? category = _keep,
    DateTime? updatedAt,
    bool? deleted,
    bool? pendingSync,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      description: identical(description, _keep)
          ? this.description
          : description as String?,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: identical(category, _keep)
          ? this.category
          : category as String?,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}

// Postgres `numeric` normally arrives as a JSON number, but be lenient.
double _toDouble(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());
