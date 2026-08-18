part of '../admin_screens.dart';

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
    child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _Metric(
              'Today Sales',
              _money(state.dashboard['today_sales']),
              'Live from payments',
              green,
            ),
            _Metric(
              'Total Bills',
              '${state.dashboard['total_bills'] ?? 0}',
              'Invoices today',
              green,
            ),
            _Metric(
              'Profit',
              _money(state.dashboard['profit']),
              'From invoice costs',
              green,
            ),
            _Metric(
              'Low Stock',
              '${state.dashboard['low_stock_count'] ?? 0}',
              'Items',
              const Color(0xFFFF3B18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Quick Actions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Quick(Icons.add_circle_outline, 'Add Product', () => state.go(5)),
            _Quick(Icons.person_add_alt, 'Add User', () => state.go(2)),
            _Quick(
              Icons.shopping_cart_outlined,
              'New Purchase',
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
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.note, this.color);
  final String title, value, note;
  final Color color;
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
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color == green ? ink : color,
          ),
        ),
        Text(note, style: TextStyle(fontSize: 9, color: color)),
      ],
    ),
  );
}

String _money(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '') ?? 0;
  return '₹ ${amount.toStringAsFixed(2)}';
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
