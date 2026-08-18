part of '../admin_screens.dart';

class PurchaseOrderScreen extends StatelessWidget {
  const PurchaseOrderScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.purchaseOrders
        .where((order) => order['status'] == 'pending')
        .toList();
    final order = pending.isEmpty ? null : pending.first;
    final items = order?['items'] as List? ?? const [];

    return _AdminPage(
      state: state,
      title: 'PO Approval',
      back: 7,
      bottom: false,
      child: order == null
          ? const _EmptyState(
              'No pending purchase orders.',
              icon: Icons.shopping_bag_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      LabeledValue(
                        'PO Number',
                        order['number']?.toString() ?? '',
                      ),
                      LabeledValue(
                        'Supplier',
                        order['supplier_name']?.toString() ?? '',
                      ),
                      LabeledValue(
                        'Order Date',
                        _dateText(order['order_date']),
                      ),
                      const SizedBox(height: 12),
                      const _TableHeader([
                        'Product',
                        'Qty',
                        'Rate (₹)',
                        'Amount (₹)',
                      ]),
                      ...items.map((rawItem) {
                        final item = rawItem as Map<String, dynamic>;
                        return _TableRow([
                          item['item_name']?.toString() ?? '',
                          item['quantity']?.toString() ?? '0',
                          item['unit_cost']?.toString() ?? '0',
                          item['amount']?.toString() ?? '0',
                        ]);
                      }),
                      const Divider(height: 24),
                      LabeledValue('Taxable Amount', _money(order['subtotal'])),
                      LabeledValue('Tax Amount', _money(order['tax_amount'])),
                      const Divider(),
                      LabeledValue('Grand Total', _money(order['total'])),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryAction(
                          'Approve',
                          color: green,
                          onPressed: () => _decideOrder(context, state, true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryAction(
                          'Reject',
                          color: red,
                          onPressed: () => _decideOrder(context, state, false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

Future<void> _decideOrder(
  BuildContext context,
  AdminState state,
  bool approved,
) async {
  try {
    await state.decidePurchaseOrder(approved);
    if (context.mounted) {
      showNotice(
        context,
        approved ? 'Purchase order approved' : 'Purchase order rejected',
      );
    }
  } catch (error) {
    if (context.mounted) showNotice(context, error.toString());
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.values);
  final List<String> values;

  @override
  Widget build(BuildContext context) => Container(
    color: page,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: values
          .asMap()
          .entries
          .map(
            (entry) => Expanded(
              flex: entry.key == 0 ? 3 : 2,
              child: Text(
                entry.value,
                textAlign: entry.key == 0 ? TextAlign.left : TextAlign.right,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _TableRow extends StatelessWidget {
  const _TableRow(this.values, {this.highlight = false});
  final List<String> values;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: values
          .asMap()
          .entries
          .map(
            (entry) => Expanded(
              flex: entry.key == 0 ? 3 : 2,
              child: Text(
                entry.value,
                textAlign: entry.key == 0 ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontSize: 9,
                  color: highlight && entry.key > 0 ? red : ink,
                  fontWeight: entry.key == 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
