import 'package:budgget_buddy/pages/add_budget.dart';
import 'package:budgget_buddy/pages/settings.dart';
import 'package:flutter/material.dart';

class DashBoardView extends StatefulWidget {
  const DashBoardView({super.key});

  @override
  State<DashBoardView> createState() => DashBoardViewState();
}

class DashBoardViewState extends State<DashBoardView> {
  final ValueNotifier<int> bottomNavNotifier = ValueNotifier<int>(0);

  late List<Widget> lstBottomScreen;

  @override
  void initState() {
    super.initState();
    lstBottomScreen = [const AddBudgetPage(), SettingsPage()];
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
