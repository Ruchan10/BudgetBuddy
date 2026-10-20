import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/widgets/category_picker.dart';
import 'package:budgget_buddy/widgets/edit_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GroupedTransactionsList extends ConsumerStatefulWidget {
  final List<Transaction> transactions;

  const GroupedTransactionsList({super.key, required this.transactions});

  @override
  ConsumerState<GroupedTransactionsList> createState() =>
      _GroupedTransactionsListState();
}

class _GroupedTransactionsListState
    extends ConsumerState<GroupedTransactionsList> {
  final _selectedId = ValueNotifier<String>('');

  @override
  void dispose() {
    _selectedId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = ref.watch(settingsProvider.select((s) => s.currencySymbol));

    final Map<int, Map<int, Map<int, List<Transaction>>>> grouped = {};
    for (var tx in widget.transactions) {
      grouped
          .putIfAbsent(tx.date.year, () => {})
          .putIfAbsent(tx.date.month, () => {})
          .putIfAbsent(tx.date.day, () => [])
          .add(tx);
    }

    if (grouped.isEmpty) {
      return Center(
        child: Text(
          'No transactions',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      );
    }

    return ListView(
      children: [
        for (final (year, months) in _newestFirst(grouped))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 16,
                  bottom: 8,
                  top: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    _TotalsRow(
                      months.values
                          .expand((days) => days.values)
                          .expand((t) => t),
                    ),
                  ],
                ),
              ),
              for (final (month, days) in _newestFirst(months))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        bottom: 8,
                        right: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat.MMM().format(DateTime(year, month)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          _TotalsRow(days.values.expand((t) => t)),
                        ],
                      ),
                    ),
                    for (final (day, dayTxs) in _newestFirst(days))
                      ValueListenableBuilder(
                        valueListenable: _selectedId,
                        builder: (context, selId, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day
                              Padding(
                                padding: const EdgeInsets.only(left: 32),
                                child: Row(
                                  spacing: 16,
                                  children: [
                                    Text(
                                      '$day',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    _TotalsRow(dayTxs),
                                  ],
                                ),
                              ),
                              for (final tx
                                  in dayTxs
                                    ..sort((a, b) => b.date.compareTo(a.date)))
                                _TransactionTile(
                                  tx: tx,
                                  symbol: symbol,
                                  isSelected: selId == tx.id,
                                  onTap: () => _selectedId.value =
                                      selId == tx.id ? '' : tx.id,
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  // Records rather than MapEntry: a `MapEntry(...)` pattern over this generic
  // call would infer V as dynamic.
  static List<(int, V)> _newestFirst<V>(Map<int, V> map) =>
      [for (final entry in map.entries) (entry.key, entry.value)]
        ..sort((a, b) => b.$1.compareTo(a.$1));
}

/// Money in, money out and the difference for a group of transactions.
class _TotalsRow extends StatelessWidget {
  const _TotalsRow(this.transactions);

  final Iterable<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    var incoming = 0.0;
    var outgoing = 0.0;
    for (final t in transactions) {
      if (t.amount > 0) {
        incoming += t.amount;
      } else {
        outgoing += t.amount.abs();
      }
    }

    return Row(
      children: [
        _total(Icons.arrow_downward, incoming, Colors.green),
        const SizedBox(width: 16),
        _total(Icons.arrow_upward, outgoing, Colors.red),
        const SizedBox(width: 16),
        _total(
          Icons.account_balance_wallet_rounded,
          incoming - outgoing,
          Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _total(IconData icon, double value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({
    required this.tx,
    required this.symbol,
    required this.isSelected,
    required this.onTap,
  });

  final Transaction tx;
  final String symbol;
  final bool isSelected;
  final VoidCallback onTap;

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final category = await showCategoryPicker(
      context,
      current: tx.category,
      custom: ref.read(customCategoriesProvider),
    );
    if (category == null || category == tx.category) return;
    await ref
        .read(transactionListProvider.notifier)
        .updateTransaction(tx.copyWith(category: category));
  }

  void _edit(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Edit Transaction",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) {
        return EditTransactionDialog(
          transaction: tx,
          onSave: (updatedTx) async {
            await ref
                .read(transactionListProvider.notifier)
                .updateTransaction(updatedTx);
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(scale: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final amountColor = tx.amount < 0 ? Colors.red : Colors.green;
    final description = tx.description;

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "- ${tx.title}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              CategoryChip(
                                category: tx.category,
                                onTap: () => _pickCategory(context, ref),
                              ),
                              if (description != null &&
                                  description.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatMoney(tx.amount.abs(), symbol),
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection tint; ignores taps so the category chip stays tappable.
              IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                right: isSelected ? 8 : -200,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _edit(context, ref),
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(transactionListProvider.notifier)
                                .deleteTransaction(tx.id);
                          },
                          icon: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
