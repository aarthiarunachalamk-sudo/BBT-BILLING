part of '../admin_screens.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final reason = TextEditingController();
  final quantity = TextEditingController();
  String method = 'cash';
  int? invoiceId;
  int? invoiceItemId;

  @override
  void initState() {
    super.initState();
    if (widget.state.invoices.isNotEmpty) {
      _selectInvoice(widget.state.invoices.first['id'] as int?);
    }
  }

  @override
  void dispose() {
    reason.dispose();
    quantity.dispose();
    super.dispose();
  }

  void _selectInvoice(int? value) {
    invoiceId = value;
    final invoice = widget.state.invoices.where((row) => row['id'] == value);
    final items = invoice.isEmpty
        ? const []
        : (invoice.first['items'] as List? ?? const []);
    invoiceItemId = items.isEmpty
        ? null
        : (items.first as Map<String, dynamic>)['id'] as int?;
  }

  Map<String, dynamic>? get selectedInvoice {
    final rows = widget.state.invoices.where((row) => row['id'] == invoiceId);
    return rows.isEmpty ? null : rows.first;
  }

  List<Map<String, dynamic>> get selectedItems =>
      (selectedInvoice?['items'] as List? ?? const [])
          .cast<Map<String, dynamic>>();

  @override
  Widget build(BuildContext context) {
    final selectedItemRows = selectedItems.where(
      (item) => item['id'] == invoiceItemId,
    );
    final selectedItem = selectedItemRows.isEmpty
        ? null
        : selectedItemRows.first;
    final unitPrice =
        double.tryParse(selectedItem?['unit_price']?.toString() ?? '') ?? 0;
    final returnQuantity = int.tryParse(quantity.text) ?? 0;

    return _AdminPage(
      state: widget.state,
      title: 'Returns & Refunds',
      back: 14,
      bottom: false,
      child: widget.state.invoices.isEmpty
          ? const _EmptyState(
              'No invoices are available for return.',
              icon: Icons.receipt_long_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: invoiceId,
                        decoration: const InputDecoration(labelText: 'Invoice'),
                        items: widget.state.invoices
                            .map(
                              (invoice) => DropdownMenuItem<int>(
                                value: invoice['id'] as int,
                                child: Text(
                                  invoice['number']?.toString() ?? '',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectInvoice(value)),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        key: ValueKey(invoiceId),
                        initialValue: invoiceItemId,
                        decoration: const InputDecoration(labelText: 'Item'),
                        items: selectedItems
                            .map(
                              (item) => DropdownMenuItem<int>(
                                value: item['id'] as int,
                                child: Text(item['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => invoiceItemId = value),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Return quantity',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: reason,
                        decoration: const InputDecoration(
                          labelText: 'Return reason',
                        ),
                      ),
                      const SizedBox(height: 14),
                      LabeledValue(
                        'Calculated Refund',
                        _money(unitPrice * returnQuantity),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Refund Method',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      ...const {
                        'cash': 'Cash',
                        'original': 'Original Payment',
                        'credit': 'Store Credit',
                        'replacement': 'Replacement',
                      }.entries.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onTap: () => setState(() => method = entry.key),
                          leading: Icon(
                            method == entry.key
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: method == entry.key ? blue : muted,
                          ),
                          title: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: PrimaryAction(
                    'Approve Refund',
                    onPressed: () async {
                      if (invoiceId == null ||
                          invoiceItemId == null ||
                          reason.text.trim().isEmpty) {
                        showNotice(
                          context,
                          'Select invoice/item and enter a return reason.',
                        );
                        return;
                      }
                      try {
                        await widget.state.approveReturn(
                          invoiceId: invoiceId!,
                          invoiceItemId: invoiceItemId!,
                          quantity: returnQuantity,
                          reason: reason.text.trim(),
                          method: method,
                        );
                        if (context.mounted) {
                          showNotice(context, 'Refund approved');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          showNotice(context, error.toString());
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
