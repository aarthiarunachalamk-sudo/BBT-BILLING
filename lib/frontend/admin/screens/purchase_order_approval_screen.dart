part of '../admin_screens.dart';

class PurchaseOrderScreen extends StatelessWidget {
  const PurchaseOrderScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'PO Approval',
    back: 7,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              LabeledValue('PO Number', 'PO-2025-0054'),
              LabeledValue('Supplier', 'Balaji Distributors'),
              LabeledValue('Order Date', '14 May 2025'),
              SizedBox(height: 12),
              _TableHeader(['Product', 'Qty', 'Rate (â‚¹)', 'Amount (â‚¹)']),
              _TableRow(['Aashirvaad Atta 5kg', '50', '210.00', '10,500.00']),
              _TableRow(['Fortune Oil 1L', '30', '150.00', '4,500.00']),
              _TableRow(['Tata Salt 1kg', '100', '16.00', '1,600.00']),
              Divider(height: 24),
              LabeledValue('Taxable Amount', 'â‚¹ 16,600.00'),
              LabeledValue('CGST (6%)', 'â‚¹ 996.00'),
              LabeledValue('SGST (6%)', 'â‚¹ 996.00'),
              Divider(),
              LabeledValue('Grand Total', 'â‚¹ 18,592.00'),
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
                  onPressed: () async {
                    await state.decidePurchaseOrder(true);
                    if (context.mounted) {
                      showNotice(context, 'Purchase order approved');
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryAction(
                  'Reject',
                  color: red,
                  onPressed: () async {
                    await state.decidePurchaseOrder(false);
                    if (context.mounted) {
                      showNotice(context, 'Purchase order rejected');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
            (e) => Expanded(
              flex: e.key == 0 ? 3 : 2,
              child: Text(
                e.value,
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right,
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
            (e) => Expanded(
              flex: e.key == 0 ? 3 : 2,
              child: Text(
                e.value,
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontSize: 9,
                  color: highlight && e.key > 0 ? red : ink,
                  fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
