import 'package:budgget_buddy/core/money.dart';
import 'package:flutter/material.dart';

/// Preset currency symbols, "None" to hide the currency, or a custom symbol.
class CurrencyPicker extends StatefulWidget {
  const CurrencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  late final _customController = TextEditingController(
    text: _isPreset(widget.value) ? '' : widget.value,
  );

  static bool _isPreset(String value) =>
      value.isEmpty || kCurrencyPresets.contains(value);

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _choosePreset(String symbol) {
    _customController.clear();
    widget.onChanged(symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final symbol in kCurrencyPresets)
              ChoiceChip(
                label: Text(symbol),
                selected: widget.value == symbol,
                onSelected: (_) => _choosePreset(symbol),
              ),
            ChoiceChip(
              label: const Text('None'),
              selected: widget.value.isEmpty,
              onSelected: (_) => _choosePreset(''),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customController,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Other symbol',
            hintText: 'e.g. NPR',
            counterText: '',
          ),
          onChanged: (text) => widget.onChanged(text.trim()),
        ),
      ],
    );
  }
}
