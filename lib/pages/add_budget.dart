import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/widgets/budget_list.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AddBudgetPage extends ConsumerStatefulWidget {
  const AddBudgetPage({super.key});

  @override
  AddBudgetPageState createState() => AddBudgetPageState();
}

class AddBudgetPageState extends ConsumerState<AddBudgetPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _focusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final Uuid _uuid = Uuid();
  final List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (Config.getUpdateAvailable()) {
          UpdateManager.showInstallDialog(context);
        }
      });
    });
  }

  Future<void> _loadTransactions() async {
    // setState(() {
    //   _transactions = transactions;
    // });
    // final prefs = UserSharedPrefs();
    // await prefs.clearTransactionList();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final title = _titleController.text.trim();
    final amt = double.tryParse(_amountController.text.trim());
    final id = _uuid.v4();

    if (title.isEmpty || amt == null) return;
    Transaction trans = Transaction(
      title: title,
      amount: amt,
      date: DateTime.now(),
      id: id,
    );

    _titleController.clear();
    _amountController.clear();
    ref.read(transactionListProvider.notifier).addTransaction(trans);
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
      ),
      body: Column(
        children: [
          Expanded(
            child: GroupedTransactionsList(
              transactions: ref.watch(transactionListProvider),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    focusNode: _focusNode,
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _amountFocusNode.requestFocus(),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  flex: 1,
                  child: TextField(
                    focusNode: _amountFocusNode,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addTransaction(),
                  ),
                ),

                const SizedBox(width: 10),

                // Add Button
                // Container(
                //   decoration: BoxDecoration(
                //     color: theme.primaryColor,
                //     shape: BoxShape.circle,
                //     boxShadow: [
                //       BoxShadow(
                //         color: theme.primaryColor.withValues(alpha: 0.4),
                //         blurRadius: 4,
                //         offset: const Offset(0, 1),
                //       ),
                //     ],
                //   ),
                //   child: IconButton(
                //     icon: const Icon(Icons.add, color: Colors.white),
                //     onPressed: _addTransaction,
                //     iconSize: 20,
                //     padding: const EdgeInsets.all(8),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
