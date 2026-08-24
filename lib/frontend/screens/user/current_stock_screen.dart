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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [
            Expanded(child: _summary('${rows.length}', 'Total Products', userBlue)),
            const SizedBox(width: 6),
            Expanded(child: _summary('${rows.where((p) => number(p['store_quantity']) > number(p['minimum_quantity'])).length}', 'In Stock', userGreen)),
            const SizedBox(width: 6),
            Expanded(child: _summary('${rows.where((p) { final q = number(p['store_quantity']); return q > 0 && q <= number(p['minimum_quantity']); }).length}', 'Low Stock', userOrange)),
            const SizedBox(width: 6),
            Expanded(child: _summary('${rows.where((p) => number(p['store_quantity']) == 0).length}', 'Out', userRed)),
          ]),
        ),
        Expanded(
          child: rows.isEmpty
              ? const EmptyMessage('No store stock matches these filters.')
              : ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20), children: [
                  Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), color: const Color(0xFFEFF6FF), child: const Row(children: [
                    Expanded(flex: 5, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w700))),
                    Expanded(flex: 2, child: Text('Store Qty', textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Minimum', textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: Text('Status', textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Move', textAlign: TextAlign.center)),
                  ])),
                  for (final product in rows) _stockRow(context, product),
                ]),
        ),
      ]),
    );
  }

  Widget _summary(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .18))),
    child: Column(children: [Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Colors.blueGrey))]),
  );

  Widget _stockRow(BuildContext context, Map<String, dynamic> product) {
    final quantity = number(product['store_quantity']);
    final minimum = number(product['minimum_quantity']);
    final status = quantity == 0 ? 'Out of Stock' : quantity <= minimum ? 'Low Stock' : 'In Stock';
    return Container(padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E6EC)))), child: Row(children: [
      Expanded(flex: 5, child: Row(children: [ProductImageWidget(imageUrl: product['image_url'] ?? product['product_image_url'], width: 40, height: 40), const SizedBox(width: 7), Expanded(child: Text('${product['product_name'] ?? product['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))])),
      Expanded(flex: 2, child: Text('$quantity', textAlign: TextAlign.center)),
      Expanded(flex: 2, child: Text('$minimum', textAlign: TextAlign.center)),
      Expanded(flex: 3, child: FittedBox(fit: BoxFit.scaleDown, child: StatusPill(status))),
      Expanded(flex: 2, child: IconButton(tooltip: 'Move to shelf', icon: const Icon(Icons.add_box_outlined, size: 20), onPressed: quantity <= 0 ? null : () => _moveToShelf(context, product))),
    ]));
  }

  Future<void> _moveToShelf(BuildContext context, Map<String, dynamic> product) async {
    final controller = TextEditingController(text: '1');
    final quantity = await showDialog<int>(context: context, builder: (context) => AlertDialog(
      title: Text('Move ${product['product_name'] ?? product['name']} to shelf'),
      content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity (available: ${number(product['store_quantity'])})')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('Move'))],
    ));
    if (quantity == null) return;
    if (quantity <= 0) {
      if (context.mounted) _notice(context, 'Enter a quantity greater than zero.');
      return;
    }
    final available = number(product['store_quantity']);
    if (quantity > available) {
      if (context.mounted) _notice(context, 'Only $available units are available in Store Stock.');
      return;
    }
    final success = await state.moveToShelf((product['product_id'] ?? product['id']) as int, quantity);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _notice(context, success ? 'Stock transferred successfully.' : state.error ?? 'Unable to complete stock transfer. Please try again.');
    }
  }
}
