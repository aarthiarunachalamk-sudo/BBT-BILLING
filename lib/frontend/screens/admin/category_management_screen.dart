part of 'admin_screens.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final query = state.categoryQuery.trim().toLowerCase();
    final filtered = state.categories.where((c) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      return name.contains(query);
    }).toList();

    return _AdminPage(
      state: state,
      title: 'Categories',
      back: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SearchBox(
              'Search categories',
              onChanged: state.setCategoryQuery,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState(
                    'No categories yet. Add one to start.',
                    icon: Icons.category_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      return _CategoryCard(
                        category: category,
                        state: state,
                        onTap: () =>
                            _openCategoryProducts(context, state, category),
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.state,
    required this.onTap,
  });

  final Map<String, dynamic> category;
  final AdminState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = category['name']?.toString() ?? '';
    final count = category['product_count'] ?? 0;
    final isActive = category['is_active'] == true;

    // Count products in this category
    final products = state.products
        .where(
          (p) =>
              p['category_name']?.toString().toLowerCase() ==
              name.toLowerCase(),
        )
        .toList();
    final inStock = products
        .where((p) => p['stock_status'] == 'in_stock')
        .length;
    final lowStock = products
        .where((p) => p['stock_status'] == 'low_stock')
        .length;
    final outOfStock = products
        .where((p) => p['stock_status'] == 'out_of_stock')
        .length;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$count product${count == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (value) => state.toggleCategory(name, value),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: muted, size: 20),
                ],
              ),
              if (products.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StockPill(inStock, 'In Stock', green),
                    const SizedBox(width: 8),
                    _StockPill(lowStock, 'Low', Colors.orange),
                    const SizedBox(width: 8),
                    _StockPill(outOfStock, 'Out', red),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.add_box_outlined, size: 16),
                      label: const Text(
                        'Add product',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill(this.count, this.label, this.color);
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count $label',
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// Opens a bottom sheet listing all products in [category] with an
/// "Add Product" button pre-selecting that category.
Future<void> _openCategoryProducts(
  BuildContext context,
  AdminState state,
  Map<String, dynamic> category,
) async {
  final categoryName = category['name']?.toString() ?? '';
  final categoryId = category['id'] as int?;

  final addProduct = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        final products = state.products
            .where(
              (p) =>
                  p['category_name']?.toString().toLowerCase() ==
                  categoryName.toLowerCase(),
            )
            .toList();

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, color: blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext, true);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Product list
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: muted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No products in $categoryName yet.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: muted),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext, true);
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add first product'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _CategoryProductRow(
                          state: state,
                          product: product,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
  if (addProduct == true) {
    state.pendingCategoryId = categoryId;
    state.go(5);
  }
}

class _CategoryProductRow extends StatelessWidget {
  const _CategoryProductRow({required this.state, required this.product});

  final AdminState state;
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final status = product['stock_status']?.toString() ?? '';
    final selling =
        double.tryParse(product['selling_price']?.toString() ?? '') ?? 0;

    final (statusColor, statusBg) = switch (status) {
      'out_of_stock' => (red, const Color(0xFFFFECEE)),
      'low_stock' => (Colors.orange, const Color(0xFFFFF4DF)),
      _ => (green, const Color(0xFFE7F7EF)),
    };

    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.square(
              dimension: 52,
              child: _ProductImage(
                url: _productImageUrl(state, product['image']),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product['sku']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: muted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(selling),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${product['stock_quantity'] ?? 0} left',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>?> _showAddCategoryDialog(
  BuildContext context,
  AdminState state,
) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => _AddCategoryDialog(state: state),
);

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.state});

  final AdminState state;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final controller = TextEditingController();
  bool saving = false;
  String? errorText;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Category'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          enabled: !saving,
          textInputAction: TextInputAction.done,
          onSubmitted: saving ? null : (_) => _save(),
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'Example: Spices, Snacks, Beverages',
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving ? null : _save,
        child: saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );

  Future<void> _save() async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      setState(() => errorText = 'Enter a category name.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      final category = await widget.state.createCategory(name);
      if (!mounted) return;
      Navigator.pop(context, category);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        saving = false;
        errorText = error.toString();
      });
    }
  }
}
