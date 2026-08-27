part of 'admin_screens.dart';

class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  String query = '';
  int? selectedInvoiceId;

  Map<String, dynamic>? get _selectedInvoice {
    final matching = widget.state.invoices.where(
      (row) => row['id'] == selectedInvoiceId,
    );
    if (matching.isNotEmpty) return matching.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final invoices = widget.state.invoices.where((invoice) {
      final searchable =
          '${invoice['number']} ${invoice['client_name']} ${invoice['client_mobile']}'
              .toLowerCase();
      return searchable.contains(query.toLowerCase().trim());
    }).toList();
    return _AdminPage(
      state: widget.state,
      title: 'WhatsApp Invoices',
      back: 14,
      bottom: false,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF20B56B),
                  child: Icon(Icons.chat_rounded, color: Colors.white),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Select an invoice, verify the mobile number and preview the message before sending.',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: SearchBox(
              'Search bill number or customer',
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: invoices.isEmpty
                ? const _EmptyState(
                    'No invoices found.',
                    icon: Icons.receipt_long_outlined,
                  )
                : RadioGroup<int>(
                    groupValue: selectedInvoiceId,
                    onChanged: (value) =>
                        setState(() => selectedInvoiceId = value),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: invoices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        final selected = selectedInvoiceId == invoice['id'];
                        final mobile =
                            invoice['client_mobile']?.toString().trim() ?? '';
                        return Material(
                          color: selected
                              ? const Color(0xFFF0EDFF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(
                              () => selectedInvoiceId = invoice['id'] as int?,
                            ),
                            onLongPress: () => _showInvoice(context, invoice),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Radio<int>(value: invoice['id'] as int),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice['number']?.toString() ??
                                              'Invoice',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${invoice['client_name'] ?? 'Walk-in customer'} • ${_dateText(invoice['invoice_date'] ?? invoice['created_at'])}',
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: muted,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          mobile.isEmpty
                                              ? 'Mobile number required'
                                              : mobile,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: mobile.isEmpty
                                                ? red
                                                : const Color(0xFF168A55),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _money(invoice['total']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _showInvoice(context, invoice),
                                        child: const Text('View'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            color: Colors.white,
            child: PrimaryAction(
              selectedInvoiceId == null
                  ? 'Select an invoice to continue'
                  : 'Send selected invoice on WhatsApp',
              onPressed: selectedInvoiceId == null
                  ? null
                  : () => _prepareWhatsApp(context, _selectedInvoice!),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _prepareWhatsApp(
    BuildContext context,
    Map<String, dynamic> invoice,
  ) async {
    final result = await showDialog<_WhatsAppDraft>(
      context: context,
      builder: (_) => _WhatsAppDraftDialog(invoice: invoice),
    );
    if (result == null || !context.mounted) return;
    var historySaved = true;
    try {
      await widget.state.resendInvoice(
        invoice,
        recipientOverride: result.mobile,
        message: result.message,
      );
    } catch (_) {
      historySaved = false;
    }
    final digits = result.mobile.replaceAll(RegExp(r'\D'), '');
    final international = digits.length == 10 ? '91$digits' : digits;
    final opened = await launchUrl(
      Uri.https('wa.me', '/$international', {'text': result.message}),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    showNotice(
      context,
      opened
          ? historySaved
                ? 'WhatsApp opened. Review and tap Send.'
                : 'WhatsApp opened. Send history will sync when the server reconnects.'
          : 'WhatsApp is unavailable on this device.',
    );
  }

  Future<void> _showInvoice(
    BuildContext context,
    Map<String, dynamic> invoice,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(invoice['number']?.toString() ?? 'Invoice Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _invoiceLine(
            'Customer',
            invoice['client_name'] ?? 'Walk-in customer',
          ),
          _invoiceLine(
            'Mobile',
            invoice['client_mobile']?.toString().trim().isNotEmpty == true
                ? invoice['client_mobile']
                : 'Not added',
          ),
          _invoiceLine(
            'Date',
            _dateText(invoice['invoice_date'] ?? invoice['created_at']),
          ),
          _invoiceLine('Total', _money(invoice['total'])),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  Widget _invoiceLine(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: muted)),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _WhatsAppDraft {
  const _WhatsAppDraft(this.mobile, this.message);
  final String mobile;
  final String message;
}

class _WhatsAppDraftDialog extends StatefulWidget {
  const _WhatsAppDraftDialog({required this.invoice});
  final Map<String, dynamic> invoice;

  @override
  State<_WhatsAppDraftDialog> createState() => _WhatsAppDraftDialogState();
}

class _WhatsAppDraftDialogState extends State<_WhatsAppDraftDialog> {
  late final TextEditingController mobile;
  late final TextEditingController message;

  @override
  void initState() {
    super.initState();
    mobile = TextEditingController(
      text: widget.invoice['client_mobile']?.toString() ?? '',
    );
    message = TextEditingController(
      text:
          'Hi ${widget.invoice['client_name'] ?? 'Customer'}, your invoice ${widget.invoice['number']} for ${_money(widget.invoice['total'])} is ready. Thank you for shopping with BBT Billing.',
    );
  }

  @override
  void dispose() {
    mobile.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const CircleAvatar(
      backgroundColor: Color(0xFFEAF9F1),
      child: Icon(Icons.chat_rounded, color: Color(0xFF20B56B)),
    ),
    title: const Text('Review WhatsApp message'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: mobile,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp number',
              prefixText: '+91 ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: message,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(labelText: 'Message preview'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          const Text(
            'WhatsApp will open with this message. You can review it once more before tapping Send.',
            style: TextStyle(fontSize: 9.5, color: muted),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed:
            mobile.text.replaceAll(RegExp(r'\D'), '').length < 10 ||
                message.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                _WhatsAppDraft(mobile.text, message.text.trim()),
              ),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Open WhatsApp'),
      ),
    ],
  );
}
