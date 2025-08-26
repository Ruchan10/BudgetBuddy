import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key});

  @override
  _AddBudgetPageState createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final List<Transaction> _transactions = [
    Transaction(description: 'Coffee Shop', amount: -5.75, date: DateTime(2024, 1, 20)),
    Transaction(description: 'Salary', amount: 2500, date: DateTime(2024, 1, 19)),
    Transaction(description: 'Groceries', amount: -76.40, date: DateTime(2024, 1, 18)),
  ];

  void _addTransaction() {
    final desc = _descriptionController.text.trim();
    final amt = double.tryParse(_amountController.text.trim());
    if (desc.isEmpty || amt == null) return;

    setState(() {
      _transactions.insert(
        0,
        Transaction(description: desc, amount: amt, date: DateTime.now()),
      );
    });

    _descriptionController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.textTheme.bodyLarge?.color),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final amountColor = tx.amount < 0 ? Colors.red : Colors.green;
                final formattedDate = DateFormat('MMM d, yyyy').format(tx.date);
                return ListTile(
                  title: Text(tx.description, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  subtitle: Text(formattedDate, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                  trailing: Text(
                    '${tx.amount > 0 ? '+' : ''}\$${tx.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Description',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Amount',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: theme.primaryColor),
                  onPressed: _addTransaction,
                  iconSize: 32,
                )
              ],
            ),
          ),
        ],
      ),

    );
  }
}
