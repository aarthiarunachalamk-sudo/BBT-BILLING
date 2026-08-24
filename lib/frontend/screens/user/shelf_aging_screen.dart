part of 'user_screens.dart';

class ShelfAgingScreen extends StatelessWidget {
  const ShelfAgingScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    return UserShell(
      state: state,
      title: 'Shelf Stock (3+ Months)',
      showBack: true,
      child: state.products.isEmpty
          ? const EmptyMessage('No shelf stock records found.')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text('Shelf Stock Table', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Shelf quantities are maintained separately from Store Stock.', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(Color(0xFFEFF6FF)),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Shelf')),
                      DataColumn(label: Text('Target')),
                      DataColumn(label: Text('Refill')),
                      DataColumn(label: Text('Store')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: [
                      for (final product in state.products)
                        DataRow(cells: [
                          DataCell(SizedBox(width: 150, child: Text('${product['product_name'] ?? product['name']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)))),
                          DataCell(Text('${number(product['shelf_quantity'] ?? product['shelf_stock'])}')),
                          DataCell(Text('${number(product['target_quantity'])}')),
                          DataCell(Text('${number(product['refill_required'])}')),
                          DataCell(Text('${number(product['store_quantity'] ?? product['store_stock'])}')),
                          DataCell(StatusPill('${product['status'] ?? 'FULL'}')),
                          DataCell(OutlinedButton(onPressed: state.loading ? null : () => _moveStock(context, product), child: const Text('Move'))),
                        ]),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _moveStock(BuildContext context, Map<String, dynamic> product) async {
    final controller = TextEditingController();
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Move ${product['product_name'] ?? product['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity', helperText: 'Available store stock: ${number(product['store_quantity'] ?? product['store_stock'])}\nRecommended refill: ${number(product['refill_required'])}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)), child: const Text('Confirm')),
        ],
      ),
    );
    controller.dispose();
    if (quantity == null || quantity <= 0) return;
    final success = await state.moveToShelf((product['product_id'] ?? product['id']) as int, quantity);
    if (context.mounted) _notice(context, success ? 'Stock moved successfully.' : state.error ?? 'Stock move failed.');
  }
}

void _notice(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
