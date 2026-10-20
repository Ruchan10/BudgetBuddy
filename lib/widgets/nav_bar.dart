import 'package:budgget_buddy/pages/add_budget.dart';
import 'package:budgget_buddy/pages/settings.dart';
import 'package:budgget_buddy/provider/settings_provider.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashBoardView extends ConsumerStatefulWidget {
  const DashBoardView({super.key});

  @override
  ConsumerState<DashBoardView> createState() => DashBoardViewState();
}

class DashBoardViewState extends ConsumerState<DashBoardView> {
  final ValueNotifier<int> bottomNavNotifier = ValueNotifier<int>(0);

  late List<Widget> lstBottomScreen;

  @override
  void initState() {
    super.initState();
    lstBottomScreen = [const AddBudgetPage(), const SettingsPage()];
    _checkForUpdateOnStart();
  }

  // Once per launch, and only if the user wants it.
  Future<void> _checkForUpdateOnStart() async {
    if (!ref.read(settingsProvider).checkUpdatesOnStart) return;
    if (await UpdateManager.checkForUpdates() && mounted) {
      UpdateManager.showUpdateDialog(context);
    }
  }

  void onTabTapped(int index) {
    setState(() {
      bottomNavNotifier.value = index;
    });
  }

  @override
  void dispose() {
    bottomNavNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ValueListenableBuilder<int>(
        valueListenable: bottomNavNotifier,
        builder: (context, index, _) {
          return lstBottomScreen[index];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomNavNotifier.value,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.textTheme.bodyMedium?.color,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: onTabTapped,
      ),
    );
  }
}
