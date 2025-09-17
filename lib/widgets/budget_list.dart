import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
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
  final prefs = UserSharedPrefs();

  double totalIncoming(List<Transaction> txs) =>
      txs.where((t) => t.amount > 0).fold(0, (sum, t) => sum + t.amount);

  double totalOutgoing(List<Transaction> txs) =>
      txs.where((t) => t.amount < 0).fold(0, (sum, t) => sum + t.amount.abs());

  double totalBalance(List<Transaction> txs) =>
      txs.fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ValueNotifier<String> selectedIdNotifier = ValueNotifier('');
    final Map<int, Map<int, Map<int, List<Transaction>>>> grouped = {};

    final transactions = ref.watch(transactionListProvider);

    for (var tx in transactions) {
      final year = tx.date.year;
      final month = tx.date.month;
      final day = tx.date.day;

      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => {});
      grouped[year]![month]!.putIfAbsent(day, () => []);
      grouped[year]![month]![day]!.add(tx);
    }

    return grouped.isEmpty
        ? Center(
            child: Text(
              'No transactions',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
          )
        : ListView(
            children: (grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key))).map((
              yearEntry,
            ) {
              Map<String, Map<String, double>> yearlyTotals = {};

              final year = yearEntry.key;
              final months = yearEntry.value;
              late String yearKey;
              for (var tx in transactions) {
                final date = tx.date;
                yearKey = "${date.year}";

                yearlyTotals.putIfAbsent(
                  yearKey,
                  () => {"incoming": 0, "outgoing": 0, "balance": 0},
                );

                if (tx.amount > 0) {
                  yearlyTotals[yearKey]!["incoming"] =
                      yearlyTotals[yearKey]!["incoming"]! + tx.amount;
                } else {
                  yearlyTotals[yearKey]!["outgoing"] =
                      yearlyTotals[yearKey]!["outgoing"]! + tx.amount.abs();
                }

                yearlyTotals[yearKey]!["balance"] =
                    yearlyTotals[yearKey]!["incoming"]! -
                    yearlyTotals[yearKey]!["outgoing"]!;
              }

              return Column(
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
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                Text(
                                  yearlyTotals[yearKey]!["incoming"]!
                                      .toStringAsFixed(0),
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                Text(
                                  yearlyTotals[yearKey]!["outgoing"]!
                                      .toStringAsFixed(0),
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                Text(
                                  yearlyTotals[yearKey]!["balance"]!
                                      .toStringAsFixed(0),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...(months.entries.toList()..sort((a, b) => b.key.compareTo(a.key))).map((
                    monthEntry,
                  ) {
                    Map<String, Map<String, double>> monthlyTotals = {};

                    final month = monthEntry.key;
                    final days = monthEntry.value;
                    late String monthKey;
                    for (var tx in transactions) {
                      final date = tx.date;
                      monthKey =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}";

                      monthlyTotals.putIfAbsent(
                        monthKey,
                        () => {"incoming": 0, "outgoing": 0, "balance": 0},
                      );

                      if (tx.amount > 0) {
                        monthlyTotals[monthKey]!["incoming"] =
                            monthlyTotals[monthKey]!["incoming"]! + tx.amount;
                      } else {
                        monthlyTotals[monthKey]!["outgoing"] =
                            monthlyTotals[monthKey]!["outgoing"]! +
                            tx.amount.abs();
                      }

                      monthlyTotals[monthKey]!["balance"] =
                          monthlyTotals[monthKey]!["incoming"]! -
                          monthlyTotals[monthKey]!["outgoing"]!;
                    }
                    return Column(
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
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_downward,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                      Text(
                                        monthlyTotals[monthKey]!["incoming"]!
                                            .toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.arrow_upward,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      Text(
                                        monthlyTotals[monthKey]!["outgoing"]!
                                            .toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      Text(
                                        monthlyTotals[monthKey]!["balance"]!
                                            .toStringAsFixed(0),
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ...(days.entries.toList()..sort((a, b) => b.key.compareTo(a.key))).map((
                          dayEntry,
                        ) {
                          final day = dayEntry.key;
                          final dayTxs = dayEntry.value;
                          final dayIncoming = totalIncoming(dayTxs);
                          final dayOutgoing = totalOutgoing(dayTxs);
                          final dayBalance = totalBalance(dayTxs);
                          return ValueListenableBuilder(
                            valueListenable: selectedIdNotifier,
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
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.arrow_downward,
                                                  size: 14,
                                                  color: Colors.green,
                                                ),
                                                Text(
                                                  dayIncoming.toStringAsFixed(
                                                    0,
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.arrow_upward,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                                Text(
                                                  dayOutgoing.toStringAsFixed(
                                                    0,
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 16),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .account_balance_wallet_rounded,
                                                  size: 14,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                Text(
                                                  dayBalance.toStringAsFixed(0),
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...(dayTxs..sort((a, b) => b.date.compareTo(a.date))).map((
                                    tx,
                                  ) {
                                    final amountColor = tx.amount < 0
                                        ? Colors.red
                                        : Colors.green;
                                    final isSelected = selId == tx.id;

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 48,
                                        right: 16,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          selectedIdNotifier.value = isSelected
                                              ? ''
                                              : tx.id!;
                                        },
                                        child: SizedBox(
                                          height: 60,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 4,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme.cardColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),

                                                  border: Border.all(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "- ${tx.title}",
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: theme
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.color,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          if (tx.description !=
                                                                  null &&
                                                              tx
                                                                  .description!
                                                                  .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 0,
                                                                    left: 8,
                                                                  ),
                                                              child: Text(
                                                                tx.description!,
                                                                style: TextStyle(
                                                                  color: theme
                                                                      .textTheme
                                                                      .bodyMedium
                                                                      ?.color,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: amountColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Rs ${tx.amount.abs().toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: amountColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 4,
                                                    ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.black.withValues(
                                                          alpha: 0.05,
                                                        )
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),

                                                child: const SizedBox.expand(),
                                              ),
                                              AnimatedPositioned(
                                                duration: const Duration(
                                                  milliseconds: 400,
                                                ),
                                                right: isSelected ? 8 : -200,
                                                // top: 8,
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: theme.cardColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        TextButton.icon(
                                                          onPressed: () {
                                                            showGeneralDialog(
                                                              context: context,
                                                              barrierDismissible:
                                                                  true,
                                                              barrierLabel:
                                                                  "Edit Transaction",
                                                              transitionDuration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                              pageBuilder:
                                                                  (
                                                                    context,
                                                                    animation1,
                                                                    animation2,
                                                                  ) {
                                                                    return EditTransactionDialog(
                                                                      transaction:
                                                                          tx,
                                                                      onSave:
                                                                          (
                                                                            updatedTx,
                                                                          ) async {
                                                                            await ref
                                                                                .read(
                                                                                  transactionListProvider.notifier,
                                                                                )
                                                                                .updateTransaction(
                                                                                  updatedTx,
                                                                                );
                                                                          },
                                                                    );
                                                                  },
                                                              transitionBuilder:
                                                                  (
                                                                    context,
                                                                    anim1,
                                                                    anim2,
                                                                    child,
                                                                  ) {
                                                                    return FadeTransition(
                                                                      opacity:
                                                                          anim1,
                                                                      child: ScaleTransition(
                                                                        scale:
                                                                            anim1,
                                                                        child:
                                                                            child,
                                                                      ),
                                                                    );
                                                                  },
                                                            );
                                                          },
                                                          icon: Icon(
                                                            Icons.edit,
                                                            size: 16,
                                                            color: theme
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                          label: Text(
                                                            "Edit",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                          ),
                                                          style: TextButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 4,
                                                                  horizontal: 8,
                                                                ),
                                                            minimumSize:
                                                                Size.zero,
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            backgroundColor:
                                                                theme
                                                                    .colorScheme
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        IconButton(
                                                          onPressed: () async {
                                                            await ref
                                                                .read(
                                                                  transactionListProvider
                                                                      .notifier,
                                                                )
                                                                .deleteTransaction(
                                                                  tx.id!,
                                                                );
                                                          },
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            size: 20,
                                                            color: Colors.red,
                                                          ),
                                                          style: TextButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 4,
                                                                  horizontal: 8,
                                                                ),
                                                            minimumSize:
                                                                Size.zero,
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            backgroundColor:
                                                                Colors.red
                                                                    .withValues(
                                                                      alpha:
                                                                          0.2,
                                                                    ),
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
                                  }),
                                ],
                              );
                            },
                          );
                        }),
                      ],
                    );
                  }),
                ],
              );
            }).toList(),
          );
  }
}
