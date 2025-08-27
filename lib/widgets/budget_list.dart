import 'package:budgget_buddy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroupedTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const GroupedTransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<int, Map<int, Map<int, List<Transaction>>>> grouped = {};

    for (var tx in transactions) {
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
                        // Transactions under this day
                        ...dayTxs.map((tx) {
                          final amountColor = tx.amount < 0
                              ? Colors.red
                              : Colors.green;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.only(
                                  left: 48,
                                  right: 16,
                                ),
                                title: Text("- ${tx.description}"),
                                trailing: Text(
                                  '${tx.amount > 0 ? '+' : ''}\$${tx.amount.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: amountColor,
                                    fontWeight: FontWeight.bold,
                                  ),
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
