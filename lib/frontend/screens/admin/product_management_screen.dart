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
                        leading: Tooltip(
                          message: 'Add or replace product image',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () =>
                                _replaceProductImage(context, state, product),
                            child: SizedBox(
                              width: 52,
                              height: 58,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _ProductImage(
                                      url: _productImageUrl(
                                        state,
                                        product['image'],
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor: blue,
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                          'GST: ${product['tax_percent'] ?? 0}% · Stock: ${product['stock_quantity'] ?? 0}'
                          '${product['mrp'] == null ? '' : ' · MRP ${_money(product['mrp'])}'}'
                          '${product['price_verified_at'] == null ? '' : '\nPrice verified ${_dateText(product['price_verified_at'])}'}',
                          style: const TextStyle(fontSize: 9, height: 1.45),
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

String? _productImageUrl(AdminState state, dynamic rawValue) {
  final value = rawValue?.toString() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final origin = state.api.baseUrl.replaceFirst(RegExp(r'/api$'), '');
  return '$origin${value.startsWith('/') ? '' : '/'}$value';
}

Future<void> _replaceProductImage(
  BuildContext context,
  AdminState state,
  Map<String, dynamic> product,
) async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (image == null) return;
  try {
    await state.updateProductImage(
      product['id'] as int,
      await image.readAsBytes(),
      image.name,
    );
    if (context.mounted) showNotice(context, 'Product image updated');
  } catch (error) {
    if (context.mounted) showNotice(context, error.toString());
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const ColoredBox(
        color: page,
        child: Icon(Icons.inventory_2_outlined, color: blue),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: page,
        child: Icon(Icons.broken_image_outlined, color: muted),
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
