import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/widgets/budget_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key});

  @override
  AddBudgetPageState createState() => AddBudgetPageState();
}

class AddBudgetPageState extends State<AddBudgetPage> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _focusNode = FocusNode();
  final _amountFocusNode = FocusNode();

  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = UserSharedPrefs();
    final list = await prefs.getTransactionList();
    setState(() {
      _transactions = list;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final desc = _descriptionController.text.trim();
    final amt = double.tryParse(_amountController.text.trim());

    if (desc.isEmpty || amt == null) return;
    Transaction trans = Transaction(
      description: desc,
      amount: amt,
      date: DateTime.now(),
    );
    setState(() {
      _transactions.insert(0, trans);
    });

    _descriptionController.clear();
    _amountController.clear();
    final prefs = UserSharedPrefs();
    await prefs.addTransaction(trans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budget',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.textTheme.bodyLarge?.color,
          ),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GroupedTransactionsList(transactions: _transactions),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _descriptionController,
                    decoration: InputDecoration(hintText: 'Description'),
                    onSubmitted: (value) {
                      _amountFocusNode.requestFocus();
                    },
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    focusNode: _amountFocusNode,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: 'Amount'),
                    onSubmitted: (value) {
                      _addTransaction();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: theme.primaryColor),
                  onPressed: _addTransaction,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
