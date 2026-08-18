part of '../admin_screens.dart';

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
            _ReportTile(Icons.bar_chart, 'Sales Report', () => state.go(10)),
            _ReportTile(
              Icons.receipt_long_outlined,
              'GST Report',
              () => showNotice(context, 'GST report opened'),
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
                'Export PDF',
                () => showNotice(context, 'PDF export started'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ExportButton(
                Icons.table_chart,
                green,
                'Export Excel',
                () => showNotice(context, 'Excel export started'),
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
          initialValue:
              state.settingsDraft['invoice_prefix']?.toString() ?? 'BILL-',
          decoration: const InputDecoration(labelText: 'Invoice Prefix'),
          onChanged: (value) => state.updateSetting('invoice_prefix', value),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _percent(state.settingsDraft['default_gst'], 5),
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
          initialValue: _percent(
            state.settingsDraft['max_cashier_discount'],
            10,
          ),
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
          initialValue: _percent(state.settingsDraft['approval_threshold'], 10),
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
          initialValue: state.settingsDraft['round_off']?.toString() ?? '0.01',
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
            await state.saveStoreSettings(state.settingsDraft);
            if (context.mounted) showNotice(context, 'Store settings saved');
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
          icon: const Icon(Icons.chat_outlined),
          label: const Text('WhatsApp Invoice Control'),
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
