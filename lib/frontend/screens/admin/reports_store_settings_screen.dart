part of 'admin_screens.dart';

class ReportsSettingsScreen extends StatelessWidget {
  const ReportsSettingsScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Reports & Store Settings',
    back: 1,
    child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'Reports',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: .92,
          children: [
            _ReportTile(Icons.bar_chart, 'Sales Report', () => state.go(17)),
            _ReportTile(
              Icons.receipt_long_outlined,
              'GST Report',
              () =>
                  _showReportPreview(context, 'GST Report', _gstReport(state)),
            ),
            _ReportTile(
              Icons.inventory_outlined,
              'Inventory Report',
              () => state.go(9),
            ),
            _ReportTile(
              Icons.shopping_bag_outlined,
              'Purchase Report',
              () => state.go(8),
            ),
            _ReportTile(
              Icons.currency_rupee,
              'Profit & Loss',
              () => state.go(10),
            ),
            _ReportTile(
              Icons.stacked_line_chart,
              'Stock Valuation',
              () => state.go(9),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Export Reports',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                Icons.picture_as_pdf,
                red,
                'Report Preview',
                () => _showReportPreview(
                  context,
                  'Admin Report Summary',
                  _reportSummary(state),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ExportButton(
                Icons.table_chart,
                green,
                'Copy CSV',
                () => _copyInvoiceCsv(context, state),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Store Settings',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: state.settingsDraft['invoice_prefix']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Invoice Prefix'),
          onChanged: (value) => state.updateSetting('invoice_prefix', value),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['default_gst'] == null
              ? null
              : _percent(state.settingsDraft['default_gst'], 0),
          decoration: const InputDecoration(labelText: 'Default GST'),
          items: [
            '0%',
            '5%',
            '12%',
            '18%',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) =>
              state.updateSetting('default_gst', value?.replaceAll('%', '')),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['max_cashier_discount'] == null
              ? null
              : _percent(state.settingsDraft['max_cashier_discount'], 0),
          decoration: const InputDecoration(labelText: 'Max Cashier Discount'),
          items: [
            '5%',
            '10%',
            '15%',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) => state.updateSetting(
            'max_cashier_discount',
            value?.replaceAll('%', ''),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: state.settingsDraft['approval_threshold'] == null
              ? null
              : _percent(state.settingsDraft['approval_threshold'], 0),
          decoration: const InputDecoration(labelText: 'Approval Threshold'),
          items: [
            '5%',
            '10%',
            '15%',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) => state.updateSetting(
            'approval_threshold',
            value?.replaceAll('%', ''),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: state.settingsDraft['round_off']?.toString() ?? '',
          decoration: const InputDecoration(labelText: 'Round Off'),
          onChanged: (value) => state.updateSetting(
            'round_off',
            value.replaceAll('â‚¹', '').trim(),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryAction(
          'Save Settings',
          onPressed: () async {
            try {
              await state.saveStoreSettings(state.settingsDraft);
              if (context.mounted) {
                showNotice(context, 'Store settings saved');
              }
            } catch (error) {
              if (context.mounted) showNotice(context, error.toString());
            }
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => state.go(12),
          icon: const Icon(Icons.assignment_return_outlined),
          label: const Text('Returns & Refunds'),
        ),
        TextButton.icon(
          onPressed: () => state.go(13),
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('All Bills & WhatsApp'),
        ),
        TextButton.icon(
          onPressed: () => state.go(15),
          icon: const Icon(Icons.security_outlined),
          label: const Text('Audit Log & Logout'),
        ),
      ],
    ),
  );
}

String _reportSummary(AdminState state) => [
  'BBT Billing - Admin Report Summary',
  'Generated: ${_dateText(DateTime.now())}',
  '',
  'Today Sales: ${_money(state.dashboard['today_sales'])}',
  'Total Bills: ${state.dashboard['total_bills'] ?? 0}',
  'Profit: ${_money(state.dashboard['profit'])}',
  'Low Stock Items: ${state.dashboard['low_stock_count'] ?? 0}',
  'Products: ${state.products.length}',
  'Suppliers: ${state.suppliers.length}',
  'Invoices: ${state.invoices.length}',
  'Pending Purchase Orders: ${state.purchaseOrders.where((row) => row['status'] == 'pending').length}',
  'Pending Discount Approvals: ${state.discountApprovals.where((row) => row['status'] == 'pending').length}',
].join('\n');

String _gstReport(AdminState state) {
  double total(String key) => state.invoices.fold<double>(
    0,
    (sum, invoice) =>
        sum + (double.tryParse(invoice[key]?.toString() ?? '') ?? 0),
  );
  return [
    'BBT Billing - GST Report',
    'Generated: ${_dateText(DateTime.now())}',
    '',
    'Invoices: ${state.invoices.length}',
    'Taxable Amount: ${_money(total('taxable_amount'))}',
    'CGST Collected: ${_money(total('cgst_amount'))}',
    'SGST Collected: ${_money(total('sgst_amount'))}',
    'Invoice Total: ${_money(total('total'))}',
  ].join('\n');
}

Future<void> _showReportPreview(
  BuildContext context,
  String title,
  String report,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(child: SelectableText(report)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (context.mounted) showNotice(context, 'Report copied');
          },
          icon: const Icon(Icons.copy_outlined, size: 17),
          label: const Text('Copy'),
        ),
      ],
    ),
  );
}

Future<void> _copyInvoiceCsv(BuildContext context, AdminState state) async {
  String csvCell(dynamic value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  final rows = <List<dynamic>>[
    [
      'Invoice',
      'Date',
      'Customer',
      'Status',
      'Taxable',
      'CGST',
      'SGST',
      'Total',
    ],
    ...state.invoices.map(
      (invoice) => [
        invoice['number'],
        invoice['invoice_date'],
        invoice['client_name'],
        invoice['status'],
        invoice['taxable_amount'],
        invoice['cgst_amount'],
        invoice['sgst_amount'],
        invoice['total'],
      ],
    ),
  ];
  final csv = rows.map((row) => row.map(csvCell).join(',')).join('\n');
  await Clipboard.setData(ClipboardData(text: csv));
  if (context.mounted) {
    showNotice(
      context,
      state.invoices.isEmpty
          ? 'CSV headers copied; no invoices are available.'
          : '${state.invoices.length} invoice rows copied as CSV',
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile(this.icon, this.label, this.tap);
  final IconData icon;
  final String label;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(7),
    child: SectionCard(
      padding: const EdgeInsets.all(7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: navy),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _ExportButton extends StatelessWidget {
  const _ExportButton(this.icon, this.color, this.label, this.tap);
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: tap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    icon: Icon(icon, color: color),
    label: Text(
      label,
      style: const TextStyle(
        color: ink,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
