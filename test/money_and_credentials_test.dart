import 'dart:convert';

import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/services/supabase_credentials.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String fakeJwt(Map<String, dynamic> payload) =>
    'eyJhbGciOiJIUzI1NiJ9.${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.sig';

void main() {
  group('formatMoney', () {
    test('places the symbol and groups digits', () {
      expect(formatMoney(1250, 'Rs'), 'Rs 1,250.00');
      expect(formatMoney(1250.5, r'$'), r'$1,250.50');
      expect(formatMoney(-3.5, '€'), '-€3.50');
      expect(formatMoney(-1000000, 'NPR'), '-NPR 1,000,000.00');
      expect(formatMoney(42, ''), '42.00');
      expect(formatMoney(42.4, '₹', decimals: 0), '₹42');
    });
  });

  group('parseAmount', () {
    test('accepts grouped numbers and rejects text', () {
      expect(parseAmount('1,250.50'), 1250.5);
      expect(parseAmount(' 10 '), 10);
      expect(parseAmount('-5'), -5);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount(''), isNull);
    });
  });

  group('SignKeyFormatter', () {
    TextEditingValue typed(String text, [int? cursor]) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor ?? text.length),
    );

    test('reports sign keys and keeps them out of the number', () {
      final keys = <String>[];
      final formatter = SignKeyFormatter(onSignKey: keys.add);
      final result = formatter.formatEditUpdate(typed('12'), typed('12-'));
      expect(result.text, '12');
      expect(result.selection.baseOffset, 2);
      expect(
        formatter.formatEditUpdate(typed('12'), typed('+12', 1)).text,
        '12',
      );
      expect(keys, ['-', '+']);
      expect(formatter.formatEditUpdate(typed('1'), typed('12')).text, '12');
      expect(keys, hasLength(2));
    });

    test('toggles a leading minus when the sign is in the text', () {
      const formatter = SignKeyFormatter();
      final negative = formatter.formatEditUpdate(
        typed('250'),
        typed('25-0', 3),
      );
      expect(negative.text, '-250');
      expect(negative.selection.baseOffset, 3);
      expect(
        formatter.formatEditUpdate(typed('-250'), typed('-250-')).text,
        '250',
      );
      expect(
        formatter.formatEditUpdate(typed('-250'), typed('-250+')).text,
        '250',
      );
      expect(
        formatter.formatEditUpdate(typed('250'), typed('250+')).text,
        '250',
      );
      expect(
        formatter.formatEditUpdate(typed('-250'), typed('250', 0)).text,
        '250',
      );
    });
  });

  group('Supabase credentials', () {
    test('normalizes pasted URLs', () {
      expect(
        normalizeSupabaseUrl(' https://abcd1234.supabase.co/rest/v1/ '),
        'https://abcd1234.supabase.co',
      );
      expect(
        normalizeSupabaseUrl(
          'https://supabase.com/dashboard/project/abcd1234/settings/api',
        ),
        'https://abcd1234.supabase.co',
      );
      expect(
        normalizeSupabaseUrl('https://db.example.com:8000/'),
        'https://db.example.com:8000',
      );
    });

    test('accepts publishable and anon keys', () {
      const url = 'https://abcd1234.supabase.co';
      expect(validateSupabaseCredentials(url, 'sb_publishable_xyz'), isNull);
      expect(
        validateSupabaseCredentials(url, fakeJwt({'role': 'anon'})),
        isNull,
      );
    });

    test('rejects secret keys, bad URLs and empty keys', () {
      const url = 'https://abcd1234.supabase.co';
      expect(validateSupabaseCredentials(url, 'sb_secret_xyz'), isNotNull);
      expect(
        validateSupabaseCredentials(url, fakeJwt({'role': 'service_role'})),
        isNotNull,
      );
      expect(validateSupabaseCredentials(url, ' '), isNotNull);
      expect(
        validateSupabaseCredentials('abcd1234', 'sb_publishable_x'),
        isNotNull,
      );
    });
  });
}
