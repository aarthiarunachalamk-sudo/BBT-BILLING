part of 'admin_screens.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final filtered = state.categories.where((category) {
      final name = category['name']?.toString().toLowerCase() ?? '';
      return name.contains(state.categoryQuery);
    }).toList();
    return _AdminPage(
      state: state,
      title: 'Category Management',
      back: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBox(
              'Search categories',
              onChanged: state.setCategoryQuery,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState(
                    'No categories found.',
                    icon: Icons.category_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      final name = category['name']?.toString() ?? '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 3),
                        leading: const Icon(
                          Icons.category_outlined,
                          color: blue,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${category['product_count'] ?? 0} Products',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Switch(
                          value: category['is_active'] == true,
                          onChanged: (value) =>
                              state.toggleCategory(name, value),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: PrimaryAction(
              'Add Category',
              icon: Icons.add,
              onPressed: () async {
                await _showAddCategoryDialog(context, state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>?> _showAddCategoryDialog(
  BuildContext context,
  AdminState state,
) async {
  final controller = TextEditingController();
  var saving = false;
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          enabled: !saving,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'Example: Spices, Snacks, Beverages',
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    setDialogState(() => saving = true);
                    try {
                      final category = await state.createCategory(name);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, category);
                      }
                    } catch (error) {
                      if (dialogContext.mounted) {
                        setDialogState(() => saving = false);
                      }
                      if (context.mounted) {
                        showNotice(context, error.toString());
                      }
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}
