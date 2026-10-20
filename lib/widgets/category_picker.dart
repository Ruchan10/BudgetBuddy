import 'package:budgget_buddy/models/category.dart';
import 'package:flutter/material.dart';

/// Returns the picked category name, or null if the sheet was dismissed.
///
/// There is deliberately no "remove": sync keeps an existing category when an
/// upload has none (so an AI-filled one isn't lost), so it would come back.
Future<String?> showCategoryPicker(
  BuildContext context, {
  String? current,
  List<String> custom = const [],
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CategorySheet(current: current, custom: custom),
  );
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.current, required this.custom});

  final String? current;
  final List<String> custom;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _newController = TextEditingController();

  @override
  void dispose() {
    _newController.dispose();
    super.dispose();
  }

  void _pick(String name) => Navigator.pop(context, name);

  void _addNew() {
    final name = _newController.text.trim();
    if (name.isNotEmpty) _pick(name);
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ...Categories.all,
      for (final name in widget.custom) Categories.of(name),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final category in options)
                  ChoiceChip(
                    avatar: Icon(category.icon, color: category.color),
                    label: Text(category.name),
                    selected: category.name == widget.current,
                    onSelected: (_) => _pick(category.name),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'New category',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addNew,
                ),
              ),
              onSubmitted: (_) => _addNew(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill with the category's icon and name; "Uncategorized" when empty.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.onTap});

  final String? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = category;
    final look = name == null ? null : Categories.of(name);
    final color = look?.color ?? theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(look?.icon ?? Icons.label_outline, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              name ?? 'Uncategorized',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: name == null ? FontStyle.italic : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
