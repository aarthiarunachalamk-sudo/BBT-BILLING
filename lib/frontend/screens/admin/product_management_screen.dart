part of 'admin_screens.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final query = state.productQuery.trim().toLowerCase();
    final visibleProducts = state.products.where((product) {
      final searchable = [
        product['name'],
        product['sku'],
        product['category_name'],
      ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
      final status = product['stock_status']?.toString();
      final matchesStock = switch (state.productStockFilter) {
        'In Stock' => status == 'in_stock',
        'Low Stock' => status == 'low_stock',
        'Out of Stock' => status == 'out_of_stock',
        _ => true,
      };
      return searchable.contains(query) && matchesStock;
    }).toList();
    return _AdminPage(
      state: state,
      title: 'Product Management',
      back: 1,
      actions: [
        PopupMenuButton<int>(
          iconColor: Colors.white,
          onSelected: state.go,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 6, child: Text('Categories')),
            PopupMenuItem(value: 7, child: Text('Suppliers')),
            PopupMenuItem(value: 9, child: Text('Inventory alerts')),
          ],
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBox(
              'Search by name, SKU or barcode',
              trailing: Icons.filter_alt_outlined,
              onTrailingTap: () => _showProductFilters(context, state),
              onChanged: state.setProductQuery,
            ),
          ),
          Expanded(
            child: visibleProducts.isEmpty
                ? _EmptyState(
                    state.products.isEmpty
                        ? 'No products found. Add your first product.'
                        : 'No products match your search.',
                    icon: Icons.inventory_2_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: visibleProducts.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = visibleProducts[index];
                      final status = product['stock_status']?.toString() ?? '';
                      final out = status == 'out_of_stock';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: page,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: blue,
                          ),
                        ),
                        title: Text(
                          product['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          'SKU: ${product['sku'] ?? ''} · ${product['category_name'] ?? ''}\n'
                          'GST: ${product['tax_percent'] ?? 0}%     Stock: ${product['stock_quantity'] ?? 0}',
                          style: const TextStyle(fontSize: 9, height: 1.5),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _money(product['selling_price']),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _statusText(status),
                              style: TextStyle(
                                fontSize: 9,
                                color: out ? red : green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: PrimaryAction(
              'Add Product',
              icon: Icons.add,
              onPressed: () => state.go(5),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showProductFilters(BuildContext context, AdminState state) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filter products by stock',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                  .map(
                    (filter) => ChoiceChip(
                      label: Text(filter),
                      selected: state.productStockFilter == filter,
                      onSelected: (_) {
                        state.setProductStockFilter(filter);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
