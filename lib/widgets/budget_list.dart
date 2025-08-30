import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupedTransactionsList extends StatefulWidget {
  final List<Transaction> transactions;

  const GroupedTransactionsList({super.key, required this.transactions});

  @override
  State<GroupedTransactionsList> createState() =>
      _GroupedTransactionsListState();
}

String selectedId = '';

class _GroupedTransactionsListState extends State<GroupedTransactionsList> {
  @override
  Widget build(BuildContext context) {
    final Map<int, Map<int, Map<int, List<Transaction>>>> grouped = {};

    for (var tx in widget.transactions) {
      final year = tx.date.year;
      final month = tx.date.month;
      final day = tx.date.day;

      grouped.putIfAbsent(year, () => {});
      grouped[year]!.putIfAbsent(month, () => {});
      grouped[year]![month]!.putIfAbsent(day, () => []);
      grouped[year]![month]![day]!.add(tx);
    }

    return ListView(
      children: grouped.entries.map((yearEntry) {
        final year = yearEntry.key;
        final months = yearEntry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '$year',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...months.entries.map((monthEntry) {
              final month = monthEntry.key;
              final days = monthEntry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      DateFormat.MMM().format(DateTime(year, month)),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...days.entries.map((dayEntry) {
                    final day = dayEntry.key;
                    final dayTxs = dayEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            '$day',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ...dayTxs.map((tx) {
                          final amountColor = tx.amount < 0
                              ? Colors.red
                              : Colors.green;
                          final isSelected = selectedId == tx.id;

                          return Padding(
                            padding: const EdgeInsets.only(left: 48, right: 16),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedId = isSelected ? '' : tx.id!;
                                });
                              },
                              child: SizedBox(
                                height: 60,
                                child: Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "- ${tx.description}",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: amountColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Rs ${tx.amount.abs().toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: amountColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
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
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.black.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 4,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      right: isSelected ? 8 : -200,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {},
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                              label: const Text(
                                                "Edit",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                minimumSize: Size
                                                    .zero, // removes Material min size
                                                tapTargetSize: MaterialTapTargetSize
                                                    .shrinkWrap, // no extra padding
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                backgroundColor: Colors.blue
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              onPressed: () {},
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                backgroundColor: Colors.red
                                                    .withValues(alpha: 0.2),
                                              ),
                                            ),
                                          ],
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
