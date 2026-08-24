part of 'user_screens.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen(this.state, {super.key});
  final UserState state;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool savingPdf = false;
  UserState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final invoice = state.lastInvoice.isNotEmpty
        ? state.lastInvoice
        : (state.invoices.isNotEmpty ? state.invoices.first : <String, dynamic>{});
    return UserShell(
      state: state,
      title: 'Invoice & Profile',
      child: invoice.isEmpty
          ? const EmptyMessage('No invoice is available yet.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                UserCard(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 54, color: userGreen),
                      const SizedBox(height: 5),
                      const Text('Payment Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const Divider(height: 28),
                      _line('Invoice ID', invoice['number']),
                      _line('Date & Time', invoice['created_at'] ?? invoice['invoice_date']),
                      _line('Cashier', state.user['first_name'] ?? state.user['username']),
                      _line('Payment status', invoice['status']),
                      _line('Total Amount', money(invoice['total'])),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: savingPdf ? null : () => _downloadPdf(invoice),
                        icon: savingPdf
                            ? const SizedBox.square(dimension: 17, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(savingPdf ? 'Saving...' : 'Download PDF'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _notice(context, 'Enter a customer mobile number during billing to send by WhatsApp.'),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Send WhatsApp'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                UserCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined, color: userBlue),
                        title: const Text('Bill History'),
                        subtitle: Text('${state.invoices.length} saved invoice${state.invoices.length == 1 ? '' : 's'}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showHistory(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined, color: userBlue),
                        title: const Text('Stock Activity'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => state.go(UserPage.stockMovement),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded, color: userBlue),
                        title: const Text('User Profile'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => state.go(UserPage.profile),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => state.go(UserPage.billing), child: const Text('Create New Bill')),
              ],
            ),
    );
  }

  Future<void> _downloadPdf(Map<String, dynamic> invoice) async {
    setState(() => savingPdf = true);
    try {
      final location = await InvoicePdfService.save(invoice);
      if (mounted) _notice(context, 'Invoice PDF saved to $location');
    } on PlatformException catch (error) {
      if (mounted) _notice(context, error.message ?? 'Could not save the invoice PDF.');
    } catch (_) {
      if (mounted) _notice(context, 'Could not create the invoice PDF.');
    } finally {
      if (mounted) setState(() => savingPdf = false);
    }
  }

  Future<void> _showHistory(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Bill History', style: TextStyle(fontWeight: FontWeight.w900))),
            if (state.invoices.isEmpty)
              const ListTile(title: Text('No saved bills yet.')),
            for (final item in state.invoices)
              ListTile(
                leading: const Icon(Icons.receipt_outlined, color: userBlue),
                title: Text('${item['number'] ?? 'Invoice'}'),
                subtitle: Text('${item['invoice_date'] ?? item['created_at'] ?? ''} • ${item['status'] ?? ''}'),
                trailing: Text(money(item['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => state.lastInvoice = item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
            Flexible(child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
