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
        UserFilterTabs(values: const ['All', 'In Stock', 'Low Stock', 'Out of Stock'], selected: state.stockFilter, onSelected: state.setStockFilter),
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
              : ListView.separated(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, index) => _stockRow(context, rows[index])),
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
    return UserCard(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProductImageWidget(imageUrl: product['image_url'] ?? product['product_image_url'], width: 48, height: 48),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('${product['product_name'] ?? product['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))), const SizedBox(width: 8), StatusPill(status)]),
        const SizedBox(height: 7),
        Text('Product ID: ${product['product_id'] ?? product['id']}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        const SizedBox(height: 5),
        Row(children: [_stockValue('Store', quantity, userBlue), const SizedBox(width: 18), _stockValue('Minimum', minimum, userOrange), const Spacer(), IconButton(tooltip: 'Move to shelf', visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_box_outlined, color: userBlue), onPressed: quantity <= 0 ? null : () => _moveToShelf(context, product)), if (state.canManageInventory) IconButton(tooltip: 'Delete product', icon: const Icon(Icons.delete_outline, color: userRed), onPressed: () => _deleteProduct(context, product))]),
      ])),
    ]));
  }

  Widget _stockValue(String label, int value, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)), Text('$value', style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w900))]);

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

  Future<void> _deleteProduct(BuildContext context, Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Delete product?'), content: Text('Delete ${product['product_name'] ?? product['name']} permanently?'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(style: FilledButton.styleFrom(backgroundColor: userRed), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete'))])) ?? false;
    if (!confirmed) return;
    final success = await state.deleteProduct(number(product['product_id'] ?? product['id']));
    if (context.mounted) _notice(context, success ? 'Product deleted.' : state.error ?? 'Product could not be deleted.');
  }
}
