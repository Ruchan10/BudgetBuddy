import 'package:budgget_buddy/core/app_info.dart';
import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/links.dart';
import 'package:budgget_buddy/core/money.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/core/snackbar.dart';
import 'package:budgget_buddy/pages/cloud_sync.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/provider/sync_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/widgets/balance_dialog.dart';
import 'package:budgget_buddy/widgets/currency_picker.dart';
import 'package:budgget_buddy/widgets/theme_mode_selector.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _checkingForUpdate = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checkingForUpdate = true);
    final available = await UpdateManager.checkForUpdates();
    if (!mounted) return;
    setState(() => _checkingForUpdate = false);
    if (available) {
      UpdateManager.showUpdateDialog(context);
    } else {
      showSnackBar(context: context, message: 'App is already up to date');
    }
  }

  Future<void> _pickCurrency(String current) async {
    var symbol = current;
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency symbol'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => CurrencyPicker(
              value: symbol,
              onChanged: (value) => setDialogState(() => symbol = value),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, symbol),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(currencySymbol: picked));
  }

  Future<void> _categorizeExisting() async {
    final changed = await ref
        .read(transactionListProvider.notifier)
        .categorizeUncategorized();
    if (!mounted) return;
    showSnackBar(
      context: context,
      message: changed == 0
          ? 'No new categories found'
          : 'Categorized $changed transaction${changed == 1 ? '' : 's'}',
    );
    // Lets the optional AI function look at whatever is still uncategorized.
    ref.read(syncProvider.notifier).sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final sync = ref.watch(syncProvider);
    final transactions = ref.watch(transactionListProvider);
    final balance =
        settings.openingBalance +
        transactions.fold(0.0, (s, t) => s + t.amount);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _SectionHeader('Appearance'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ThemeModeSelector(),
          ),

          const _SectionHeader('Money'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency symbol'),
            subtitle: Text(
              settings.currencySymbol.isEmpty
                  ? 'Hidden'
                  : settings.currencySymbol,
            ),
            onTap: () => _pickCurrency(settings.currencySymbol),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Current balance'),
            subtitle: Text(formatMoney(balance, settings.currencySymbol)),
            onTap: () => showBalanceDialog(context, ref),
          ),

          const _SectionHeader('Transactions'),
          SwitchListTile(
            secondary: const Icon(Icons.keyboard_outlined),
            title: const Text('Open keyboard on start'),
            subtitle: const Text('Start typing a new entry right away'),
            value: settings.openKeyboardOnStart,
            onChanged: (value) =>
                notifier.update((s) => s.copyWith(openKeyboardOnStart: value)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Auto-categorize'),
            subtitle: const Text(
              'Guesses a category on this device and learns from your changes',
            ),
            value: settings.autoCategorize,
            onChanged: (value) =>
                notifier.update((s) => s.copyWith(autoCategorize: value)),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Categorize existing transactions'),
            subtitle: const Text('Fill in categories that are still empty'),
            onTap: _categorizeExisting,
          ),

          const _SectionHeader('Cloud sync'),
          ListTile(
            leading: Icon(
              sync.error != null
                  ? Icons.sync_problem
                  : sync.signedIn
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
            title: const Text('Sync with Supabase'),
            subtitle: Text(describeSyncState(sync)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRoute.cloudSyncRoute),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Setup guide'),
            subtitle: const Text('Step by step, with copy-paste SQL'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, AppRoute.supabaseGuideRoute),
          ),

          if (AppInfo.updateCheckerEnabled) ...[
            const _SectionHeader('Updates'),
            SwitchListTile(
              secondary: const Icon(Icons.update),
              title: const Text('Check for updates on start'),
              subtitle: const Text('Looks for new releases on GitHub'),
              value: settings.checkUpdatesOnStart,
              onChanged: (value) => notifier.update(
                (s) => s.copyWith(checkUpdatesOnStart: value),
              ),
            ),
            ListTile(
              leading: Icon(
                Config.getUpdateAvailable()
                    ? Icons.download_rounded
                    : Icons.system_update_outlined,
                color: Config.getUpdateAvailable() ? Colors.green : null,
              ),
              title: Text(
                Config.getUpdateAvailable()
                    ? 'Update available'
                    : 'Check for updates now',
              ),
              subtitle: Text('Installed: ${Config.getAppVersion()}'),
              trailing: _checkingForUpdate
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _checkingForUpdate
                  ? null
                  : Config.getUpdateAvailable()
                  ? () => UpdateManager.showUpdateDialog(context)
                  : _checkForUpdates,
            ),
          ],

          const _SectionHeader('Support'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${AppInfo.name} is free and has no ads or tracking. '
              'If it helps you, you can support its development.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final link in AppInfo.donationLinks)
                  FilledButton.tonalIcon(
                    onPressed: () => openLink(link.url),
                    icon: const Icon(Icons.favorite_outline),
                    label: Text(link.label),
                  ),
                OutlinedButton.icon(
                  onPressed: () => openLink(AppInfo.repoUrl),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Star on GitHub'),
                ),
              ],
            ),
          ),

          const _SectionHeader('About'),
          ListTile(
            leading: Image.asset('assets/images/logo.webp', width: 40),
            title: const Text(AppInfo.name),
            subtitle: Text(
              'Version ${Config.getAppVersion()}\n'
              'A simple, private, offline-first budget tracker.',
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source code'),
            subtitle: Text(AppInfo.repoUrl.replaceFirst('https://', '')),
            onTap: () => openLink(AppInfo.repoUrl),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a problem'),
            onTap: () => openLink(AppInfo.issuesUrl),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Open-source licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: Config.getAppVersion(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Made by ${AppInfo.developer}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
