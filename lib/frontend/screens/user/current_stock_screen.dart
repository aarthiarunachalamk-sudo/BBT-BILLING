part of 'user_screens.dart';

class CurrentStockScreen extends StatelessWidget {
  const CurrentStockScreen(this.state, {super.key});

  final UserState state;

  @override
  Widget build(BuildContext context) {
    final groupedProducts = <String, List<Map<String, dynamic>>>{};
    for (final product in state.visibleProducts) {
      final category = product['category_name']?.toString().trim();
      final section = category == null || category.isEmpty ? 'Other Products' : category;
      groupedProducts.putIfAbsent(section, () => []).add(product);
    }
    final sections = groupedProducts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return UserShell(
      state: state,
      title: state.selectedCategoryName.isEmpty
          ? 'Inventory Products'
          : state.selectedCategoryName,
      showBack: true,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: TextField(
            onChanged: state.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search product / scan barcode',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.qr_code_scanner),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final filter in ['All', 'In Stock', 'Low Stock', 'Out of Stock'])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: state.stockFilter == filter,
                    onSelected: (_) => state.setStockFilter(filter),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: sections.isEmpty
              ? const EmptyMessage('No products match these filters.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  children: [
                    for (final section in sections) ...[
                      _ProductSectionHeader(
                        name: section,
                        count: groupedProducts[section]!.length,
                      ),
                      const SizedBox(height: 8),
                      for (final product in groupedProducts[section]!) ...[
                        _InventoryProductCard(product),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
        ),
      ]),
    );
  }
}

class _ProductSectionHeader extends StatelessWidget {
  const _ProductSectionHeader({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: userBlue,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        name,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    ),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: userBlue.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count ${count == 1 ? 'item' : 'items'}',
        style: const TextStyle(
          color: userBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  ]);
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard(this.product);

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) => UserCard(
    child: Row(children: [
      UserProductImage(
        imageUrl: product['image']?.toString(),
        quantity: number(product['total_stock'] ?? product['stock_quantity']),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${product['name']}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'SKU ${product['sku'] ?? '—'}',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
            Text(
              'Store ${number(product['store_stock'])}  •  Shelf ${number(product['shelf_stock'])}  •  Total ${number(product['total_stock'] ?? product['stock_quantity'])}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      StatusPill('${product['stock_status'] ?? 'in_stock'}'),
    ]),
  );
}
