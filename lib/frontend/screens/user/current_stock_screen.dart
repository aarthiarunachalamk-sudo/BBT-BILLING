part of 'user_screens.dart';

class CurrentStockScreen extends StatelessWidget {
  const CurrentStockScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final query = state.search.toLowerCase().trim();
    final rows = state.products.where((product) {
      final name = '${product['product_name'] ?? product['name']}';
      final matchesSearch = query.isEmpty || '$name ${product['product_id']} ${product['location_label'] ?? product['store_section'] ?? ''} ${product['rack_location'] ?? ''}'.toLowerCase().contains(query);
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
              hintText: 'Search product, section or rack',
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
        if ('${product['location_label'] ?? ''}'.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: userBlue.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: userBlue.withValues(alpha: .18)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_outlined, size: 13, color: userBlue),
              const SizedBox(width: 4),
              Text('${product['location_label']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: userBlue)),
            ]),
          ),
        ],
        const SizedBox(height: 5),
        Row(children: [_stockValue('Store', quantity, userBlue), const SizedBox(width: 18), _stockValue('Minimum', minimum, userOrange), const Spacer(), IconButton(tooltip: 'Move to shelf', visualDensity: VisualDensity.compact, icon: const Icon(Icons.add_box_outlined, color: userBlue), onPressed: quantity <= 0 ? null : () => _moveToShelf(context, product)), if (state.canManageInventory) IconButton(tooltip: 'Schedule product price', visualDensity: VisualDensity.compact, icon: const Icon(Icons.currency_rupee_rounded, color: userGreen), onPressed: () => _schedulePrice(context, product)), if (state.canManageInventory) IconButton(tooltip: 'Delete product', icon: const Icon(Icons.delete_outline, color: userRed), onPressed: () => _deleteProduct(context, product))]),
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

  Future<void> _schedulePrice(BuildContext context, Map<String, dynamic> stock) async {
    final productId = number(stock['product_id'] ?? stock['id']);
    Map<String, dynamic> product;
    try {
      product = await state.api.getMap('products/$productId');
    } on UserApiException catch (error) {
      if (context.mounted) _notice(context, error.message);
      return;
    }
    if (!context.mounted) return;
    final purchase = TextEditingController(text: '${product['purchase_price'] ?? 0}');
    final selling = TextEditingController(text: '${product['selling_price'] ?? 0}');
    var gst = double.tryParse('${product['tax_percent'] ?? ''}')?.round() ?? 0;
    const gstSlabs = [0, 5, 12, 18, 28];
    if (!gstSlabs.contains(gst)) gst = 18;
    var effectiveDate = DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          title: Text('Schedule price — ${product['name'] ?? stock['product_name']}'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Choose Today or Tomorrow. Saving the same date again edits that schedule; existing invoices stay unchanged.', style: Theme.of(dialogContext).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(controller: purchase, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Buying price', prefixText: '₹ ')),
            const SizedBox(height: 10),
            TextField(controller: selling, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price', prefixText: '₹ ')),
            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerLeft, child: Text('GST Slab *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
            const SizedBox(height: 7),
            Row(children: gstSlabs.map((slab) => Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                label: Text('$slab%', style: const TextStyle(fontSize: 10)),
                selected: gst == slab,
                selectedColor: userBlue,
                labelStyle: TextStyle(color: gst == slab ? Colors.white : userNavy),
                onSelected: (_) => setDialog(() => gst = slab),
              ),
            ))).toList()),
            const SizedBox(height: 10),
            Row(children: [
              ChoiceChip(
                avatar: const Icon(Icons.today_outlined, size: 16),
                label: const Text('Today'),
                selected: _sameUserCalendarDay(effectiveDate, DateTime.now()),
                onSelected: (_) {
                  final now = DateTime.now();
                  setDialog(() => effectiveDate = DateTime(now.year, now.month, now.day));
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.next_plan_outlined, size: 16),
                label: const Text('Tomorrow'),
                selected: _sameUserCalendarDay(effectiveDate, DateTime.now().add(const Duration(days: 1))),
                onSelected: (_) {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  setDialog(() => effectiveDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day));
                },
              ),
            ]),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: dialogContext, initialDate: effectiveDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (picked != null) setDialog(() => effectiveDate = picked);
              },
              child: InputDecorator(decoration: const InputDecoration(labelText: 'Price effective from', prefixIcon: Icon(Icons.calendar_month_outlined)), child: Text('${effectiveDate.day.toString().padLeft(2, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.year}')),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save schedule')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final success = await state.scheduleProductPrice(productId, {
      'purchase_price': purchase.text.trim(),
      'selling_price': selling.text.trim(),
      'tax_percent': gst.toString(),
      'effective_date': '${effectiveDate.year.toString().padLeft(4, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}',
    });
    if (context.mounted) _notice(context, success ? 'Price schedule saved.' : state.error ?? 'Could not save price schedule.');
  }
}

bool _sameUserCalendarDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
