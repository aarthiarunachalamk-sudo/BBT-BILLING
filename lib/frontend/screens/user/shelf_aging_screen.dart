part of 'user_screens.dart';

class ShelfAgingScreen extends StatelessWidget {
  const ShelfAgingScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return UserShell(
      state: state,
      title: 'Shelf Stock — 3+ Months',
      showBack: true,
      child: state.products.isEmpty
          ? const EmptyMessage('No shelf stock records found.')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.products.length,
              itemBuilder: (_, index) {
                final product = state.products[index];
                final added = DateTime.tryParse('${product['shelf_added_date']}');
                final age = added == null ? null : today.difference(added).inDays;
                final status = age == null ? 'Review' : age >= 90 ? 'Slow Moving' : 'Normal';
                return UserCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${product['product_name'] ?? product['name']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                      StatusPill('${product['status'] ?? status}'),
                    ]),
                    const SizedBox(height: 8),
                    Text('Shelf: ${number(product['shelf_quantity'] ?? product['shelf_stock'])}  •  Target: ${number(product['target_quantity'])}'),
                    Text('Refill required: ${number(product['refill_required'])}  •  Store: ${number(product['store_quantity'] ?? product['store_stock'])}'),
                    Text('Added: ${added == null ? 'Not recorded' : '${added.day}/${added.month}/${added.year}'}  •  Age: ${age == null ? '—' : '$age days'}'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 5, children: [
                      OutlinedButton(onPressed: state.loading ? null : () => _moveStock(context, product), child: const Text('Move Stock', style: TextStyle(fontSize: 10))),
                      for (final action in ['Apply Discount', 'Return Supplier', 'Mark Clearance'])
                        OutlinedButton(onPressed: () => _notice(context, '$action requires manager approval and is unavailable for this staff role.'), child: Text(action, style: const TextStyle(fontSize: 10))),
                    ]),
                  ]),
                );
              },
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
