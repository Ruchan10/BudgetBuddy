import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/core/snackbar.dart';
import 'package:budgget_buddy/core/theme_provider.dart';
import 'package:budgget_buddy/main.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: isDark
            ? AppColors.darkPrimary
            : AppColors.lightPrimary,
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: ListView(
        children: [
          // 🔄 Update Check
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _UpdateSection(),
          ),
          const Divider(),

          // 🌗 Theme Switch
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
        ],
      ),
    );
  }
}

class _UpdateSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final updateAvailable = Config.getUpdateAvailable();
    return Container(
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(context.heightDivisor(55)),
      // ),
      // padding: EdgeInsets.symmetric(
      //   horizontal: context.widthDivisor(853),
      //   vertical: context.heightDivisor(55),
      // ),
      child: Column(
        children: [
          updateAvailable
              ? _buildUpdateBtn(context)
              : _buildNoUpdateBtn(context),
        ],
      ),
    );
  }

  Widget _buildUpdateBtn(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => UpdateManager.showUpdateDialog(context),
      icon: Icon(Icons.download),
      label: Text('Update Available'),
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
    );
  }

  Widget _buildNoUpdateBtn(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.check_circle_rounded, color: Colors.green),
        Text(
          'App is up to date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () async {
            UpdateManager.checkForUpdates();
            if (Config.getUpdateAvailable()) {
              UpdateManager.showUpdateDialog(context);
            } else {
              showSnackBar(
                context: context,
                message: 'App is already up to date',
              );
            }
          },
        ),
      ],
    );
  }
}
