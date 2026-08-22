part of 'user_screens.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final data = state.dashboard;
    return UserShell(
      state: state,
      title: 'Dashboard',
      child: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.72,
              children: [
                _DashboardMetric(
                  label: "Today's Sales",
                  value: money(data['today_sales']),
                  color: userGreen,
                  icon: Icons.currency_rupee_rounded,
                ),
                _DashboardMetric(
                  label: 'Available Products',
                  value: '${data['active_products'] ?? 0}',
                  color: userBlue,
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    state.clearSelectedCategory();
                    state.setStockFilter('In Stock');
                    state.go(UserPage.currentStock);
                  },
                ),
                _DashboardMetric(
                  label: 'Low Stock',
                  value: '${data['low_stock_count'] ?? 0}',
                  color: userOrange,
                  icon: Icons.warning_rounded,
                  warning: true,
                ),
                _DashboardMetric(
                  label: 'Expiring Soon',
                  value: '${data['expiring_soon_count'] ?? 0}',
                  color: userRed,
                  icon: Icons.warning_rounded,
                  warning: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Inventory Quick Access',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuickAction(
                  label: 'Current\nStock',
                  icon: Icons.inventory_2_outlined,
                  color: userBlue,
                  onTap: () {
                    state.clearSelectedCategory();
                    state.go(UserPage.currentStock);
                  },
                ),
                _QuickAction(
                  label: 'Shelf Stock\n3+ Months',
                  icon: Icons.shelves,
                  color: userGreen,
                  onTap: () => state.go(UserPage.shelfAging),
                ),
                _QuickAction(
                  label: 'Quantity\nReview',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFFFF6B00),
                  onTap: () => state.go(UserPage.quantityReview),
                ),
                _QuickAction(
                  label: 'Expiry\nProducts',
                  icon: Icons.warning_amber_rounded,
                  color: userRed,
                  onTap: () => state.go(UserPage.expiry),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              "Today's Payments",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            _PaymentsCard(data: data),
          ],
        ),
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.warning = false,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool warning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: .065),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: color.withValues(alpha: .24)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            if (warning) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 19, color: color),
            ],
          ],
        ),
      ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 5),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 9, height: 1.15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDDE5F0))),
    child: Column(
      children: [
        _PaymentRow(icon: Icons.check_circle, label: 'GPay / UPI', value: data['upi_collection'], color: userGreen),
        _PaymentRow(icon: Icons.account_balance_wallet_rounded, label: 'Cash', value: data['cash_collection'], color: const Color(0xFFFF6B00)),
        _PaymentRow(icon: Icons.credit_card_rounded, label: 'Card', value: data['card_collection'], color: const Color(0xFF6D28D9)),
        const Divider(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(children: [const Expanded(child: Text('Total Collection', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600))), Text(money(data['total_collection']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: userNavy))]),
        ),
      ],
    ),
  );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [Icon(icon, size: 17, color: color), const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))), Text(money(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: userNavy))]),
  );
}
