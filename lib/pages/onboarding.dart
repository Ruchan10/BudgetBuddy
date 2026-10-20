import 'package:budgget_buddy/core/app_info.dart';
import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/widgets/currency_picker.dart';
import 'package:budgget_buddy/widgets/theme_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First-run setup. Everything here can be changed later in Settings.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _balanceController = TextEditingController();
  late String _currency;
  late bool _checkUpdates;
  String? _balanceError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _currency = settings.currencySymbol;
    _checkUpdates = settings.checkUpdatesOnStart;
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final text = _balanceController.text.trim();
    final balance = text.isEmpty ? null : parseAmount(text);
    if (text.isNotEmpty && balance == null) {
      setState(() => _balanceError = 'Enter a number, or leave it empty');
      return;
    }

    final settings = ref.read(settingsProvider.notifier);
    if (balance != null) {
      // Transactions already recorded (or restored by sync) count towards it.
      final recorded = ref.read(transactionListProvider.notifier).total;
      await settings.setOpeningBalance(balance - recorded);
    }
    await settings.update(
      (s) => s.copyWith(
        currencySymbol: _currency,
        checkUpdatesOnStart: _checkUpdates,
        onboardingComplete: true,
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoute.navRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Center(
              child: SizedBox(
                height: 72,
                child: Image.asset('assets/images/logo.webp'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to ${AppInfo.name}',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A few quick choices and you are ready. '
              'You can change all of them later in Settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),

            const _Heading('Currency'),
            CurrencyPicker(
              value: _currency,
              onChanged: (symbol) => setState(() => _currency = symbol),
            ),

            const _Heading('Current balance'),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: _currency.isEmpty ? null : '$_currency ',
                helperText:
                    'Money you have right now. Leave empty to start at 0.',
                helperMaxLines: 2,
                errorText: _balanceError,
              ),
            ),

            const _Heading('Theme'),
            const ThemeModeSelector(),

            if (AppInfo.updateCheckerEnabled) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Check for updates on start'),
                subtitle: const Text('Looks for new versions on GitHub'),
                value: _checkUpdates,
                onChanged: (value) => setState(() => _checkUpdates = value),
              ),
            ],

            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Using Budget Buddy on another device?'),
                subtitle: const Text(
                  'Optional: sync through your own free Supabase project.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoute.cloudSyncRoute),
              ),
            ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
