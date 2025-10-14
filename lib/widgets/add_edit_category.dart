import 'package:budgget_buddy/models/category.dart';
import 'package:budgget_buddy/provider/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart'
    as FlutterIconPicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showCategoryEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  Category? existingCategory,
}) async {
  final isEditing = existingCategory != null;

  final nameController = TextEditingController(
    text: existingCategory?.name ?? '',
  );
  IconData? selectedIcon =
      existingCategory != null && existingCategory.icon.isNotEmpty
      ? IconData(
          int.tryParse(existingCategory.icon) ?? Icons.category.codePoint,
          fontFamily: 'MaterialIcons',
        )
      : Icons.category; // Default fallback
  Color selectedColor = existingCategory != null
      ? Color(int.parse('0xff${existingCategory.color.replaceFirst('#', '')}'))
      : Colors.blue;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ), // More rounded for modern look
        title: Text(
          isEditing ? 'Edit Category' : 'Add Category',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(
                  16,
                ), // Add padding for breathing room
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field - Enhanced with better styling
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: const Icon(
                          Icons.label_outline,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'e.g., Food & Drinks',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20), // Increased spacing
                    // Icon Picker - Improved with preview and better handling
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          selectedIcon,
                          color: selectedColor,
                          size: 28,
                        ),
                        title: const Text(
                          'Select Icon',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Tap to choose from a variety of icons and emojis',
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () async {
                          IconPickerIcon?
                          icon = await FlutterIconPicker.showIconPicker(
                            context,
                            configuration: SinglePickerConfiguration(
                              iconPackModes: [
                                IconPack.material,
                                IconPack.cupertino,
                                IconPack.allMaterial,
                              ], // Include multiple packs for variety, including emojis if supported
                            ),
                          );
                          if (icon != null) {
                            setState(() => selectedIcon = icon.data);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Color Picker - Enhanced with better preview and layout
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selectedColor,
                          radius: 14,
                        ),
                        title: const Text(
                          'Select Color',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('Current: ${selectedColor.toString()}'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text('Pick a Color'),
                                content: BlockPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (color) =>
                                      setState(() => selectedColor = color),
                                  availableColors: const [
                                    Colors.red,
                                    Colors.green,
                                    Colors.blue,
                                    Colors.yellow,
                                    Colors.orange,
                                    Colors.purple,
                                    Colors.pink,
                                    Colors.teal,
                                    Colors.indigo,
                                    Colors.brown,
                                  ], // Limit to common colors for better UX
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Done'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Preview Section - New addition for better UX
                    const Divider(),
                    const Text(
                      'Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: selectedColor,
                          child: Icon(selectedIcon, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          nameController.text.isEmpty
                              ? 'Category Name'
                              : nameController.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: selectedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Update' : 'Add'),
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }
              final newCategory = Category(
                name: nameController.text.trim(),
                icon:
                    selectedIcon?.codePoint.toString() ??
                    Icons.category.codePoint.toString(),
                color:
                    '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}',
              );
              try {
                final notifier = ref.read(categoryListProvider.notifier);
                if (isEditing) {
                  notifier.updateCategory(newCategory);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category updated successfully'),
                    ),
                  );
                } else {
                  notifier.addCategory(newCategory);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category added successfully'),
                    ),
                  );
                }
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
        ],
      );
    },
  );
}
