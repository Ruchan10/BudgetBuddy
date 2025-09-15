import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/snackbar.dart';
import 'package:budgget_buddy/main.dart';
import 'package:budgget_buddy/provider/theme_provider.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  final _serviceKeyController = TextEditingController();

  Widget _buildUpdateBtn(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => UpdateManager.showUpdateDialog(context),
      icon: Icon(Icons.download_rounded),
      label: Text('Update Available'),
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
    );
  }

  Widget _buildNoUpdateBtn(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        UpdateManager.checkForUpdates();
        if (Config.getUpdateAvailable()) {
          UpdateManager.showUpdateDialog(context);
        } else {
          showSnackBar(context: context, message: 'App is already up to date');
        }
      },
      child: Row(
        spacing: 16,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green),
          Text(
            'App is up to date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final updateAvailable = Config.getUpdateAvailable();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: isDark
            ? AppColors.darkPrimary
            : AppColors.lightPrimary,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: updateAvailable
                ? _buildUpdateBtn(context)
                : _buildNoUpdateBtn(context),
          ),
          const Divider(),

          SwitchListTile(
            secondary: Icon(
              Icons.brightness_6,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            title: Text(
              "Dark Mode",
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            value: isDark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).toggleTheme(value);
            },
          ),

          const Divider(),

          Text(
            "Sync Across Devices",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: "Project URL",
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _anonKeyController,
            decoration: InputDecoration(
              labelText: "Anon Key",
              prefixIcon: Icon(Icons.vpn_key),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _serviceKeyController,
            decoration: InputDecoration(
              labelText: "Service Role Key",
              prefixIcon: Icon(Icons.admin_panel_settings),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {
              showSnackBar(
                context: context,
                message: "Attempting to sync with Supabase...",
              );
            },
            icon: Icon(Icons.cloud_upload),
            label: Text("Sign Up & Sync"),
          ),

          const SizedBox(height: 12),

          Text(
            "To sync data across devices, enter your Supabase Project URL and keys. "
            "Follow this guide",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
