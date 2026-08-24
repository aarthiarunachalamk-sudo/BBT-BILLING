part of 'user_screens.dart';

class CurrentStockScreen extends StatelessWidget {
  const CurrentStockScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final query = state.search.toLowerCase().trim();
    final rows = state.products.where((product) {
      final name = '${product['product_name'] ?? product['name']}';
      final matchesSearch = query.isEmpty || '$name ${product['product_id']}'.toLowerCase().contains(query);
      final quantity = number(product['store_quantity']);
      final matchesFilter = state.stockFilter == 'All' ||
          (state.stockFilter == 'In Stock' && quantity > 0) ||
          (state.stockFilter == 'Low Stock' && quantity > 0 && quantity <= number(product['minimum_quantity'])) ||
          (state.stockFilter == 'Out of Stock' && quantity == 0);
      return matchesSearch && matchesFilter;
    }).toList();

    return UserShell(
      state: state,
      title: 'Store Stock',
      showBack: true,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: TextField(
            onChanged: state.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search store products',
              prefixIcon: Icon(Icons.search),
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
          child: rows.isEmpty
              ? const EmptyMessage('No store stock matches these filters.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  children: [
                    const Text('Store Stock Table', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Store quantities are maintained separately from Shelf Stock.', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: const WidgetStatePropertyAll(Color(0xFFEFF6FF)),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Store Qty')),
                          DataColumn(label: Text('Minimum')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: [
                          for (final product in rows)
                            DataRow(cells: [
                              DataCell(SizedBox(width: 170, child: Text('${product['product_name'] ?? product['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))),
                              DataCell(Text('${number(product['store_quantity'])}')),
                              DataCell(Text('${number(product['minimum_quantity'])}')),
                              DataCell(StatusPill(number(product['store_quantity']) == 0 ? 'Out of Stock' : number(product['store_quantity']) <= number(product['minimum_quantity']) ? 'Low Stock' : 'In Stock')),
                            ]),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}
