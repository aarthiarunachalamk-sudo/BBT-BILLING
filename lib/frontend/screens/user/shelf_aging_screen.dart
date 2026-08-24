part of 'user_screens.dart';

class ShelfAgingScreen extends StatelessWidget {
  const ShelfAgingScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) => UserShell(
    state: state, title: 'Shelf Stock (3+ Months)', showBack: true,
    child: Column(children: [
      SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 10), children: [
        for (final tab in ['All Stock', 'Shelf Stock', '3+ Months', 'Low Stock'])
          Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text(tab), selected: tab == '3+ Months', onSelected: (_) {})),
      ])),
      Expanded(child: state.products.isEmpty ? const EmptyMessage('No shelf stock records found.') : ListView(padding: const EdgeInsets.fromLTRB(10, 6, 10, 16), children: [
        _header(), for (final product in state.products) _row(product),
      ])),
    ]),
  );

  Widget _header() => Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), color: const Color(0xFFEFF6FF), child: const Row(children: [
    Expanded(flex: 5, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w700))), Expanded(flex: 2, child: Text('Shelf Qty', textAlign: TextAlign.center)), Expanded(flex: 3, child: Text('Added Date', textAlign: TextAlign.center)), Expanded(flex: 2, child: Text('Age', textAlign: TextAlign.center)), Expanded(flex: 3, child: Text('Status', textAlign: TextAlign.center)),
  ]));

  Widget _row(Map<String, dynamic> product) {
    final rawDate = product['shelf_added_date']?.toString();
    final date = rawDate == null ? '-' : rawDate.length >= 10 ? rawDate.substring(5, 10) : rawDate;
    final age = number(product['age_days'] ?? 0);
    return Container(padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E6EC)))), child: Row(children: [
      Expanded(flex: 5, child: Row(children: [ProductImageWidget(imageUrl: product['image_url'] ?? product['product_image_url'], width: 38, height: 38), const SizedBox(width: 6), Expanded(child: Text('${product['product_name'] ?? product['name']}', maxLines: 2, overflow: TextOverflow.ellipsis))])),
      Expanded(flex: 2, child: Text('${number(product['shelf_quantity'] ?? product['shelf_stock'])}', textAlign: TextAlign.center)), Expanded(flex: 3, child: Text(date, textAlign: TextAlign.center)), Expanded(flex: 2, child: Text(age == 0 ? '-' : '${age}d', textAlign: TextAlign.center)), Expanded(flex: 3, child: FittedBox(fit: BoxFit.scaleDown, child: StatusPill('${product['status'] ?? 'FULL'}'))),
    ]));
  }
}
