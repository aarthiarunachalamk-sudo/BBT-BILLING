part of 'admin_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Admin Dashboard',
    actions: [
      IconButton(
        onPressed: () => state.go(9),
        icon: const Icon(Icons.notifications_none),
      ),
    ],
    child: RefreshIndicator(
      onRefresh: () async {
        await state.refreshDashboard();
        if (context.mounted && state.error != null) {
          showNotice(context, state.error!);
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Store overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor today’s performance and resolve operational exceptions.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: constraints.maxWidth >= 900 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 150,
              children: [
                _Metric(
                  'Today Sales',
                  _money(state.dashboard['today_sales']),
                  '${_growth(state.dashboard['sales_growth'])} vs yesterday',
                  _growthTone(state.dashboard['sales_growth']),
                ),
                _Metric(
                  'Total Bills',
                  '${state.dashboard['total_bills'] ?? 0}',
                  '${_growth(state.dashboard['bills_growth'])} vs yesterday',
                  _growthTone(state.dashboard['bills_growth']),
                ),
                _Metric(
                  'Profit',
                  _money(state.dashboard['profit']),
                  '${_growth(state.dashboard['profit_growth'])} vs yesterday',
                  _growthTone(state.dashboard['profit_growth']),
                ),
                _Metric(
                  'Low Stock',
                  '${state.dashboard['low_stock_count'] ?? 0}',
                  'Items requiring attention',
                  muted,
                  const Color(0xFFFF3B18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DashboardOperations(state),
        ],
      ),
    ),
  );
}

class _DashboardOperations extends StatelessWidget {
  const _DashboardOperations(this.state);

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final attention = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Needs attention',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _AlertRow(
            Icons.warning_amber_rounded,
            Colors.orange,
            'Pending Discount Approvals',
            '${state.dashboard['pending_discount_approvals'] ?? 0}',
            () => state.go(11),
          ),
          const Divider(),
          _AlertRow(
            Icons.shopping_bag_outlined,
            blue,
            'Pending Purchase Orders',
            '${state.dashboard['pending_purchase_orders'] ?? 0}',
            () => state.go(8),
          ),
          const Divider(),
          _AlertRow(
            Icons.inventory_outlined,
            red,
            'Inventory Exceptions',
            '${state.dashboard['low_stock_count'] ?? 0}',
            () => state.go(9),
          ),
        ],
      ),
    );
    final quickActions = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick actions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 14,
            runSpacing: 16,
            children: [
              _Quick(Icons.add_box_outlined, 'Add Product', () => state.go(5)),
              _Quick(Icons.person_add_alt, 'Add User', () => state.go(2)),
              _Quick(
                Icons.shopping_cart_outlined,
                'Purchase Orders',
                () => state.go(8),
              ),
              _Quick(
                Icons.analytics_outlined,
                'Sales Report',
                () => state.go(10),
              ),
            ],
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [attention, const SizedBox(height: 12), quickActions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: attention),
            const SizedBox(width: 12),
            Expanded(child: quickActions),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.title,
    this.value,
    this.note,
    this.noteColor, [
    this.valueColor = ink,
  ]);
  final String title, value, note;
  final Color valueColor, noteColor;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
        Text(
          note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, color: noteColor),
        ),
      ],
    ),
  );
}

String _money(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '') ?? 0;
  return '₹ ${amount.toStringAsFixed(2)}';
}

Color _growthTone(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '') ?? 0;
  return amount < 0 ? red : green;
}

String _percent(dynamic value, int fallback) {
  final amount = double.tryParse(value?.toString() ?? '');
  return '${amount?.round() ?? fallback}%';
}

class _AlertRow extends StatelessWidget {
  const _AlertRow(this.icon, this.color, this.label, this.count, this.tap);
  final IconData icon;
  final Color color;
  final String label, count;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(count, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.tap);
  final IconData icon;
  final String label;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: blue),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
