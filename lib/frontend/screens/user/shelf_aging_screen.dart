part of 'user_screens.dart';

class ShelfAgingScreen extends StatefulWidget {
  const ShelfAgingScreen(this.state, {super.key});
  final UserState state;
  @override State<ShelfAgingScreen> createState() => _ShelfAgingScreenState();
}

class _ShelfAgingScreenState extends State<ShelfAgingScreen> {
  String _tab = '3+ Months';
  final Set<int> _selectedProductIds = {};
  UserState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;
    final selected = rows.where((row) => _selectedProductIds.contains(_id(row))).toList();
    return UserShell(state: state, title: _tab == '3+ Months' ? 'Shelf Stock (3+ Months)' : 'Shelf Stock', showBack: true, child: Column(children: [
      UserFilterTabs(values: const ['All Stock', 'Shelf Stock', '3+ Months', 'Low Stock'], selected: _tab, onSelected: (tab) => setState(() { _tab = tab; _selectedProductIds.clear(); })),
      _header(),
      Expanded(child: rows.isEmpty ? const EmptyMessage('No shelf stock records match this filter.') : RefreshIndicator(onRefresh: state.refresh, child: ListView.builder(padding: const EdgeInsets.fromLTRB(10, 0, 10, 8), itemCount: rows.length, itemBuilder: (_, index) => _row(rows[index])))),
      _actions(context, selected),
    ]));
  }

  List<Map<String, dynamic>> get _filteredRows => state.products.where((product) {
    final quantity = number(product['shelf_quantity'] ?? product['shelf_stock']);
    final age = number(product['age_days']);
    final minimum = number(product['minimum_quantity']);
    return switch (_tab) { 'Shelf Stock' => quantity > 0, '3+ Months' => quantity > 0 && age >= 90, 'Low Stock' => quantity > 0 && quantity <= minimum, _ => true };
  }).toList();
  int _id(Map<String, dynamic> product) => int.tryParse('${product['product_id'] ?? product['id']}') ?? -1;

  Widget _header() => Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), color: const Color(0xFFEFF6FF), child: const Row(children: [
    Expanded(flex: 5, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w700))), Expanded(flex: 2, child: Text('Shelf Qty', textAlign: TextAlign.center)), Expanded(flex: 3, child: Text('Added Date', textAlign: TextAlign.center)), Expanded(flex: 3, child: Text('Duration of Product', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))), Expanded(flex: 3, child: Text('Status', textAlign: TextAlign.center)),
  ]));

  Widget _row(Map<String, dynamic> product) {
    final selected = _selectedProductIds.contains(_id(product));
    final rawDate = product['shelf_added_date']?.toString();
    final date = rawDate == null ? '-' : rawDate.length >= 10 ? rawDate.substring(5, 10) : rawDate;
    return Material(color: selected ? userBlue.withValues(alpha: .10) : Colors.transparent, child: InkWell(onTap: () => setState(() => selected ? _selectedProductIds.remove(_id(product)) : _selectedProductIds.add(_id(product))), child: Container(padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E6EC)))), child: Row(children: [
      SizedBox(
        width: 34,
        child: Checkbox(
          value: selected,
          onChanged: (_) => setState(
            () => selected
                ? _selectedProductIds.remove(_id(product))
                : _selectedProductIds.add(_id(product)),
          ),
        ),
      ),
      Expanded(flex: 5, child: Row(children: [ProductImageWidget(imageUrl: product['image_url'] ?? product['product_image_url'], width: 38, height: 38), const SizedBox(width: 6), Expanded(child: Text('${product['product_name'] ?? product['name']}', maxLines: 2, overflow: TextOverflow.ellipsis))])),
      Expanded(flex: 2, child: Text('${number(product['shelf_quantity'] ?? product['shelf_stock'])}', textAlign: TextAlign.center)), Expanded(flex: 3, child: Text(date, textAlign: TextAlign.center)), Expanded(flex: 3, child: Text(_duration(number(product['age_days'])), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))), Expanded(flex: 3, child: FittedBox(fit: BoxFit.scaleDown, child: StatusPill('${product['status'] ?? 'FULL'}'))),
    ]))));
  }

  String _duration(int days) { if (days <= 0) return '-'; final months = days ~/ 30; final remainder = days % 30; return months == 0 ? '$days days' : remainder == 0 ? '$months months' : '$months months $remainder days'; }

  Widget _actions(BuildContext context, List<Map<String, dynamic>> selected) => Container(padding: const EdgeInsets.fromLTRB(10, 5, 10, 12), child: Column(children: [
    if (selected.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Select one or more shelf products to enable an action.', style: TextStyle(fontSize: 11, color: Colors.blueGrey))) else Row(children: [Text('${selected.length} selected', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: userBlue)), const Spacer(), TextButton(onPressed: () => setState(_selectedProductIds.clear), child: const Text('Clear selection'))]),
    Row(children: [Expanded(child: OutlinedButton(onPressed: selected.isEmpty ? null : () => _quantityAction(context, selected, 'move-to-store', 'Move Stock to Store'), child: const Text('Move Stock'))), const SizedBox(width: 6), Expanded(child: OutlinedButton(onPressed: selected.isEmpty ? null : () => _discountAction(context, selected, 'apply-discount', 'Apply Discount'), child: const Text('Apply Discount')))]),
    const SizedBox(height: 6), Row(children: [Expanded(child: OutlinedButton(onPressed: selected.isEmpty ? null : () => _quantityAction(context, selected, 'return-supplier', 'Return to Supplier'), child: const Text('Return Supplier'))), const SizedBox(width: 6), Expanded(child: OutlinedButton(onPressed: selected.isEmpty ? null : () => _discountAction(context, selected, 'clearance', 'Mark Clearance'), child: const Text('Mark Clearance')))]),
  ]));

  Future<void> _quantityAction(BuildContext context, List<Map<String, dynamic>> selected, String action, String title) async {
    final controller = TextEditingController(text: '1');
    final minimumAvailable = selected.map((product) => number(product['shelf_quantity'])).reduce((a, b) => a < b ? a : b);
    final quantity = await showDialog<int>(context: context, builder: (dialogContext) => AlertDialog(title: Text('$title (${selected.length} products)'), content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Same quantity for each (max: $minimumAvailable)')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)), child: const Text('Confirm'))]));
    if (quantity == null || quantity <= 0) return;
    if (quantity > minimumAvailable) { if (context.mounted) _notice(context, 'Maximum common quantity is $minimumAvailable units.'); return; }
    final result = await state.bulkShelfProductAction(selected.map(_id).toList(), action, {'quantity': quantity});
    if (result.isComplete) setState(_selectedProductIds.clear);
    if (context.mounted) _notice(context, result.isComplete ? '${result.completed} product${result.completed == 1 ? '' : 's'} updated successfully.' : '${result.completed} updated, ${result.failed} failed.');
  }

  Future<void> _discountAction(BuildContext context, List<Map<String, dynamic>> selected, String action, String title) async {
    final controller = TextEditingController();
    final percent = await showDialog<double>(context: context, builder: (dialogContext) => AlertDialog(title: Text('$title (${selected.length} products)'), content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Same discount percentage for each')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, double.tryParse(controller.text)), child: const Text('Confirm'))]));
    if (percent == null || percent <= 0 || percent > 100) { if (context.mounted && percent != null) _notice(context, 'Enter a discount between 1 and 100 percent.'); return; }
    final result = await state.bulkShelfProductAction(selected.map(_id).toList(), action, {'discount_percent': percent});
    if (result.isComplete) setState(_selectedProductIds.clear);
    if (context.mounted) _notice(context, result.isComplete ? '${result.completed} product${result.completed == 1 ? '' : 's'} updated successfully.' : '${result.completed} updated, ${result.failed} failed.');
  }
}
