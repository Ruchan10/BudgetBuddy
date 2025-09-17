class DashBoardViewState extends State<DashBoardView> {
  final ValueNotifier<int> bottomNavNotifier = ValueNotifier<int>(0);

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const AddBudgetContent(), // <-- now a content widget, not a Scaffold
      const SettingsPageContent(), // adjust similarly
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = bottomNavNotifier.value;

    return Scaffold(
      resizeToAvoidBottomInset: true, // important
      appBar: AppBar(
        title: Text(index == 0 ? 'Budget' : 'Settings',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        centerTitle: true,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.textTheme.bodyMedium?.color,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (i) => setState(() => bottomNavNotifier.value = i),
      ),
    );
  }
}
