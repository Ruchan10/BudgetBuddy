import 'package:budgget_buddy/core/config.dart';
import 'package:budgget_buddy/models/category.dart';
import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/category_provider.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:budgget_buddy/widgets/budget_list.dart';
import 'package:budgget_buddy/widgets/update_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Serialization/icondata_serialization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class AddBudgetPage extends ConsumerStatefulWidget {
  const AddBudgetPage({super.key});

  @override
  AddBudgetPageState createState() => AddBudgetPageState();
}

class AddBudgetPageState extends ConsumerState<AddBudgetPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _focusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  final Uuid _uuid = Uuid();
  bool _isPositive = false;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (Config.getUpdateAvailable()) {
          UpdateManager.showUpdateDialog(context);
        }
      });
    });
  }

  Future<void> _loadTransactions() async {
    // setState(() {
    //   _transactions = transactions;
    // });
    // final prefs = UserSharedPrefs();
    // await prefs.clearTransactionList();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    final title = _titleController.text.trim();
    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null) return;
    final signedAmt = _isPositive ? amt : -amt;
    final id = _uuid.v4();

    if (title.isEmpty) return;
    Transaction trans = Transaction(
      title: title,
      amount: signedAmt,
      category: _selectedCategory,
      date: DateTime.now(),
      id: id,
    );

    _titleController.clear();
    _amountController.clear();
    _selectedCategory = null;
    ref.read(transactionListProvider.notifier).addTransaction(trans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomNavHeight = kBottomNavigationBarHeight;
    final bottomPadding = (keyboardInset - bottomNavHeight).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Budget',
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GroupedTransactionsList(
              transactions: ref.watch(transactionListProvider),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.cardColor.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      onSubmitted: (_) => _amountFocusNode.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 1,
                    child: TextField(
                      focusNode: _amountFocusNode,
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _isPositive = !value.startsWith('-');
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Amount',
                        prefixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPositive = !_isPositive;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            width: 40,
                            child: Text(
                              _isPositive ? "+" : "-",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isPositive ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isPositive ? Colors.green : Colors.red,
                            width: 2.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_categoryFocusNode);
                        Future.delayed(const Duration(milliseconds: 150), () {
                          final dropdown = _categoryFocusNode.context
                              ?.findRenderObject();
                          if (dropdown != null) {
                            GestureBinding.instance.handlePointerEvent(
                              PointerDownEvent(position: Offset.zero),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 1,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final categories = ref.watch(categoryListProvider);
                        final selectedColor = _selectedCategory != null
                            ? Color(
                                int.parse(
                                  '0xff${_selectedCategory!.color.replaceFirst('#', '')}',
                                ),
                              )
                            : Colors.grey;
                        final dropdownKey = GlobalKey();

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedColor, width: 2),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Category?>(
                              key: dropdownKey,

                              value: _selectedCategory,
                              isExpanded: true,
                              hint: Row(
                                children: const [
                                  Icon(
                                    Icons.category_outlined,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Category',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              items: categories.isEmpty
                                  ? [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('No categories available'),
                                      ),
                                    ]
                                  : categories.map((cat) {
                                      return DropdownMenuItem(
                                        value: cat,
                                        child: Row(
                                          children: [
                                            Icon(
                                              deserializeIcon(cat.icon)?.data ??
                                                  Icons.category,
                                              color: Color(
                                                int.parse(
                                                  '0xff${cat.color.replaceFirst('#', '')}',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                cat.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                                _addTransaction();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
