part of '../admin_screens.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen(this.state, {super.key});
  final AdminState state;
  static const products = [
    [
      'ðŸ¥«',
      'Aashirvaad Atta 5kg',
      'SKU: AASH5000  Â·  MRP: â‚¹240.00',
      'â‚¹ 215.00',
      '120',
      'In Stock',
    ],
    [
      'ðŸ§´',
      'Fortune Oil 1L',
      'SKU: FORT-OIL1L  Â·  MRP: â‚¹160.00',
      'â‚¹ 140.00',
      '85',
      'In Stock',
    ],
    [
      'ðŸ¥›',
      'Amul Fresh Milk 1L',
      'SKU: AMULMILK-1L  Â·  MRP: â‚¹60.00',
      'â‚¹ 60.00',
      '45',
      'In Stock',
    ],
    [
      'ðŸµ',
      'Tata Salt 1kg',
      'SKU: TATA-SALT-1KG  Â·  MRP: â‚¹20.00',
      'â‚¹ 18.00',
      '0',
      'Out of Stock',
    ],
  ];
  List<List<String>> get displayProducts => state.products.isEmpty
      ? products
      : state.products.map((p) {
          final status = (p['stock_status'] ?? '').toString();
          return <String>[
            'ðŸ“¦',
            p['name'].toString(),
            'SKU: ${p['sku']} Â· ${p['category_name'] ?? ''}',
            _money(p['selling_price']),
            '${p['stock_quantity'] ?? 0}',
            status == 'out_of_stock'
                ? 'Out of Stock'
                : status == 'low_stock'
                ? 'Low Stock'
                : 'In Stock',
          ];
        }).toList();
  @override
  Widget build(BuildContext context) => _AdminPage(
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
        const Padding(
          padding: EdgeInsets.all(12),
          child: SearchBox(
            'Search by name, SKU or barcode',
            trailing: Icons.filter_alt_outlined,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayProducts.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final p = displayProducts[i];
              final out = p[5] == 'Out of Stock';
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
                  child: Text(p[0], style: const TextStyle(fontSize: 26)),
                ),
                title: Text(
                  p[1],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${p[2]}\nGST: ${i == 3 ? '0%' : '5%'}     Stock: ${p[4]}',
                  style: const TextStyle(fontSize: 9, height: 1.5),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p[3],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      p[5],
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
