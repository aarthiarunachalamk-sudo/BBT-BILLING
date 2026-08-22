part of 'admin_screens.dart';

class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final invoices = widget.state.invoices.where((invoice) {
      final searchable = '${invoice['number']} ${invoice['client_name']} ${invoice['client_mobile']}'.toLowerCase();
      return searchable.contains(query.toLowerCase().trim());
    }).toList();
    return _AdminPage(
      state: widget.state,
      title: 'All Bills',
      back: 14,
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: SearchBox('Search bill number or customer', onChanged: (value) => setState(() => query = value)),
        ),
        Expanded(
          child: invoices.isEmpty
              ? const _EmptyState('No invoices found.', icon: Icons.receipt_long_outlined)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: invoices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                      title: Text(invoice['number']?.toString() ?? 'Invoice', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      subtitle: Text('${invoice['client_name'] ?? 'Walk-in customer'} • ${_dateText(invoice['invoice_date'] ?? invoice['created_at'])}', style: const TextStyle(fontSize: 10)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_money(invoice['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(_statusText(invoice['status']), style: const TextStyle(fontSize: 9, color: muted)),
                        ],
                      ),
                      onTap: () => _showInvoice(context, invoice),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: PrimaryAction(
            'Send Latest Invoice on WhatsApp',
            outlined: true,
            onPressed: widget.state.invoices.isEmpty ? null : () => _sendLatest(context),
          ),
        ),
      ]),
    );
  }

  Future<void> _sendLatest(BuildContext context) async {
    try {
      await widget.state.resendInvoice();
      if (context.mounted) showNotice(context, 'Invoice queued for WhatsApp');
    } catch (error) {
      if (context.mounted) showNotice(context, error.toString());
    }
  }

  Future<void> _showInvoice(BuildContext context, Map<String, dynamic> invoice) async {
    final items = (invoice['items'] as List? ?? const []);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(invoice['number']?.toString() ?? 'Invoice Details'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _invoiceLine('Customer', invoice['client_name'] ?? 'Walk-in customer'),
              _invoiceLine('Date', _dateText(invoice['invoice_date'] ?? invoice['created_at'])),
              _invoiceLine('Status', _statusText(invoice['status'])),
              const Divider(),
              for (final item in items.whereType<Map>())
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['item_name']?.toString() ?? 'Product'),
                  subtitle: Text('Qty ${item['quantity'] ?? 0}'),
                  trailing: Text(_money(item['line_total'] ?? item['amount'])),
                ),
              const Divider(),
              _invoiceLine('Total', _money(invoice['total'])),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Widget _invoiceLine(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: muted))), Text('$value', style: const TextStyle(fontWeight: FontWeight.w700))]),
  );
}
