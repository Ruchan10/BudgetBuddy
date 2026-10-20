import 'dart:ui' as ui;

import 'package:intl/intl.dart';

// dart format off
/// Currency symbols offered in onboarding and Settings.
const kCurrencyPresets = [
  'Rs', '₹', r'$', '€', '£', '¥', '৳', '₩', '₱', '₦', 'RM', 'Rp', 'kr', 'CHF',
];
// dart format on

final _endsWithLetter = RegExp(r'\p{L}$', unicode: true);

/// Formats [amount] with the user's currency [symbol]: `Rs 1,250.00`,
/// `$1,250.00`, `-€3.50`. An empty symbol hides the currency.
String formatMoney(double amount, String symbol, {int decimals = 2}) {
  final number = NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: decimals,
  ).format(amount.abs());
  final sign = amount < 0 ? '-' : '';
  if (symbol.isEmpty) return '$sign$number';
  // Word-like symbols read better with a space: "Rs 100" but "$100".
  final gap = _endsWithLetter.hasMatch(symbol) ? ' ' : '';
  return '$sign$symbol$gap$number';
}

/// Parses user input such as `1,250.50`. Returns null when it isn't a number.
double? parseAmount(String text) =>
    double.tryParse(text.replaceAll(',', '').replaceAll(' ', '').trim());

/// A sensible starting currency for the device's region.
String defaultCurrencySymbol() {
  final country = ui.PlatformDispatcher.instance.locale.countryCode;
  return _symbolByCountry[country] ?? 'Rs';
}

// dart format off
const _symbolByCountry = {
  'NP': 'Rs', 'IN': '₹', 'PK': 'Rs', 'LK': 'Rs', 'BD': '৳', 'US': r'$',
  'GB': '£', 'JP': '¥', 'CN': '¥', 'KR': '₩', 'PH': '₱', 'NG': '₦',
  'MY': 'RM', 'ID': 'Rp', 'AU': r'A$', 'CA': r'C$', 'NZ': r'NZ$', 'SG': r'S$',
  'CH': 'CHF', 'SE': 'kr', 'NO': 'kr', 'DK': 'kr', 'BR': r'R$', 'ZA': 'R',
  'AT': '€', 'BE': '€', 'CY': '€', 'DE': '€', 'EE': '€', 'ES': '€', 'FI': '€',
  'FR': '€', 'GR': '€', 'HR': '€', 'IE': '€', 'IT': '€', 'LT': '€', 'LU': '€',
  'LV': '€', 'MT': '€', 'NL': '€', 'PT': '€', 'SI': '€', 'SK': '€',
};
// dart format on
