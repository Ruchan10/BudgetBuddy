import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/sync_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/widgets/balance_dialog.dart';
import 'package:budgget_buddy/widgets/budget_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _isPositive = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _focusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  // The numpad's "-" key flips the sign; "+" makes it positive.
  void _onSignKey(String key) =>
      setState(() => _isPositive = key == '+' || !_isPositive);

  Future<void> _addTransaction() async {
    final title = _titleController.text.trim();
    final amt = parseAmount(_amountController.text);
    if (title.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    if (amt == null) {
      _amountFocusNode.requestFocus();
      return;
    }

    _titleController.clear();
    _amountController.clear();
    // Ready for the next entry when the keyboard-first setting is on.
    if (ref.read(settingsProvider).openKeyboardOnStart) {
      _focusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }

    // The category is filled in automatically and can be changed later.
    await ref
        .read(transactionListProvider.notifier)
        .addTransaction(
          Transaction(
            title: title,
            amount: _isPositive ? amt.abs() : -amt.abs(),
            date: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomNavHeight = kBottomNavigationBarHeight;
    final bottomPadding = (keyboardInset - bottomNavHeight).clamp(
      0.0,
      double.infinity,
    );
    final transactions = ref.watch(transactionListProvider);
    final settings = ref.watch(settingsProvider);
    final balance =
        settings.openingBalance +
        transactions.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: InkWell(
          onTap: () => showBalanceDialog(context, ref),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Balance',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  formatMoney(balance, settings.currencySymbol),
                  style: TextStyle(
                    color: balance < 0
                        ? Colors.red
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        centerTitle: true,
        actions: const [_SyncStatusButton()],
      ),
      body: Column(
        children: [
          Expanded(child: GroupedTransactionsList(transactions: transactions)),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.cardColor.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _titleController,
                      autofocus: settings.openKeyboardOnStart,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        prefixIcon: Icon(Icons.description_outlined),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        SignKeyFormatter(onSignKey: _onSignKey),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Amount',
                        prefixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPositive = !_isPositive;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            width: 40,
                            child: Text(
                              _isPositive ? "+" : "-",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isPositive ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isPositive ? Colors.green : Colors.red,
                            width: 2.5,
                          ),
                        ),
                      ),
                      // Handled here so the keyboard doesn't close between entries.
                      onEditingComplete: _addTransaction,
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton.filled(
                    tooltip: 'Add',
                    onPressed: _addTransaction,
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cloud icon showing whether everything has been synced. Tap to sync now.
class _SyncStatusButton extends ConsumerWidget {
  const _SyncStatusButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    if (!sync.signedIn) return const SizedBox.shrink();
    ref.watch(transactionListProvider);
    final pending = ref
        .read(transactionListProvider.notifier)
        .hasPendingChanges;

    final Widget icon;
    final String tooltip;
    if (sync.syncing) {
      icon = const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      tooltip = 'Syncing…';
    } else if (sync.error != null) {
      icon = const Icon(Icons.sync_problem, color: Colors.orange);
      tooltip = sync.error!;
    } else if (pending) {
      icon = const Icon(Icons.cloud_upload_outlined);
      tooltip = 'Changes waiting to sync';
    } else {
      icon = const Icon(Icons.cloud_done_outlined);
      tooltip = 'Synced';
    }

    return IconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: () => ref.read(syncProvider.notifier).sync(),
    );
  }
}
