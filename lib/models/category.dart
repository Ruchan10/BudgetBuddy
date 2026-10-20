import 'package:flutter/material.dart';

class TxCategory {
  const TxCategory(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

class Categories {
  Categories._();

  static const income = 'Income';

  /// Built-in categories. The Supabase `categorize` function uses the same
  /// names, so keep supabase/functions/categorize/index.ts in step.
  static const all = <TxCategory>[
    TxCategory('Food & Drinks', Icons.restaurant, Colors.orange),
    TxCategory('Groceries', Icons.local_grocery_store, Colors.lightGreen),
    TxCategory('Transport', Icons.directions_bus, Colors.blue),
    TxCategory('Shopping', Icons.shopping_bag, Colors.pink),
    TxCategory('Bills & Utilities', Icons.receipt_long, Colors.indigo),
    TxCategory('Rent & Housing', Icons.home, Colors.brown),
    TxCategory('Health', Icons.medical_services, Colors.red),
    TxCategory('Personal Care', Icons.spa, Colors.purple),
    TxCategory('Entertainment', Icons.movie, Colors.deepPurple),
    TxCategory('Education', Icons.school, Colors.teal),
    TxCategory('Travel', Icons.flight, Colors.cyan),
    TxCategory('Gifts & Donations', Icons.card_giftcard, Colors.amber),
    TxCategory(income, Icons.payments, Colors.green),
    TxCategory('Other', Icons.category, Colors.blueGrey),
  ];

  static bool isBuiltIn(String name) => all.any((c) => c.name == name);

  /// Icon and colour for [name]; custom categories get a generic look.
  static TxCategory of(String name) => all.firstWhere(
    (c) => c.name == name,
    orElse: () => TxCategory(name, Icons.label_outline, Colors.blueGrey),
  );
}
