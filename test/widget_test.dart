children: (grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)))
    .map((yearEntry) {
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
          ...(months.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key)))
              .map((monthEntry) {
                final month = monthEntry.key;
                final days = monthEntry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ...(days.entries.toList()
                          ..sort((a, b) => b.key.compareTo(a.key)))
                        .map((dayEntry) {
                          final day = dayEntry.key;
                          final dayTxs = dayEntry.value;

                          return ValueListenableBuilder(
                            valueListenable: selectedIdNotifier,
                            builder: (context, selId, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  ...(dayTxs..sort((a, b) => b.date.compareTo(a.date)))
                                      .map((tx) {
                                        return Text(tx.title); // replace with your widget
                                      })
                                      .toList(),
                                ],
                              );
                            },
                          );
                        })
                        .toList(),
                  ],
                );
              })
              .toList(),
        ],
      );
    })
    .toList(), // ✅ now you end with List<Widget>
