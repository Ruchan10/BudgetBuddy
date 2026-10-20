import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for the money the user has right now. Transactions stay untouched;
/// the difference is stored as the starting balance.
Future<void> showBalanceDialog(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final recorded = ref.read(transactionListProvider.notifier).total;
  final balance = await showDialog<double>(
    context: context,
    builder: (context) => _BalanceDialog(
      current: settings.openingBalance + recorded,
      symbol: settings.currencySymbol,
    ),
  );
  if (balance == null) return;
  await ref
      .read(settingsProvider.notifier)
      .setOpeningBalance(balance - recorded);
}

class _BalanceDialog extends StatefulWidget {
  const _BalanceDialog({required this.current, required this.symbol});

  final double current;
  final String symbol;

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  late final _controller = TextEditingController(
    text: widget.current.toStringAsFixed(2),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = parseAmount(_controller.text);
    if (value == null) {
      setState(() => _error = 'Enter a number');
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Current balance'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          prefixText: widget.symbol.isEmpty ? null : '${widget.symbol} ',
          helperText: 'How much money you have right now.',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
