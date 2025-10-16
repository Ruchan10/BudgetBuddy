import 'package:budgget_buddy/core/snackbar.dart';
import 'package:budgget_buddy/core/user_shared_prefs.dart';
import 'package:budgget_buddy/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryListProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
      return CategoryNotifier();
    });

class CategoryNotifier extends StateNotifier<List<Category>> {
  List<Category> categories = [];
  CategoryNotifier() : super([]) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = UserSharedPrefs();
    final list = await prefs.getCategoryList();
    state = list;
  }

  bool _isNameUnique(String name) {
    return state.every((cat) => cat.name != name);
  }

  Future<void> addCategory(Category cat, BuildContext context) async {
    if (!_isNameUnique(cat.name)) {
      showSnackBar(context: context, message: 'Category name must be unique');
      return;
    }
    final prefs = UserSharedPrefs();
    await prefs.saveCategoryList([...state, cat]);
    await _loadCategories();
  }

  Future<void> updateCategory(Category cat, BuildContext context) async {
    if (!_isNameUnique(cat.name)) {
      showSnackBar(context: context, message: 'Category name must be unique');
      return;
    }
    final prefs = UserSharedPrefs();
    await prefs.saveCategoryList(
      state.map((c) => c.name == cat.name ? cat : c).toList(),
    );
    await _loadCategories();
  }

  Future<void> deleteCategory(String name) async {
    debugPrint('Deleting category: $name');
    final prefs = UserSharedPrefs();
    await prefs.saveCategoryList(state.where((c) => c.name != name).toList());
    await _loadCategories();
  }
}
