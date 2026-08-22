part of 'user_screens.dart';

class UserDashboardScreen extends StatelessWidget { const UserDashboardScreen(this.state, {super.key}); final UserState state;
  @override Widget build(BuildContext context) { final d = state.dashboard; return UserShell(state: state, title: 'Dashboard', child: RefreshIndicator(onRefresh: state.refresh, child: ListView(padding: const EdgeInsets.all(14), children: [
    Text('Welcome, ${state.user['first_name'] ?? 'Staff'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
    GridView.count(crossAxisCount: MediaQuery.sizeOf(context).width > 400 ? 4 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .92, children: [
      SummaryTile(label: "Today's Sales", value: money(d['today_sales']), icon: Icons.currency_rupee, color: userBlue), SummaryTile(label: 'Products', value: '${d['active_products'] ?? d['products'] ?? 0}', icon: Icons.inventory_2, color: userGreen),
      SummaryTile(label: 'Low Stock', value: '${d['low_stock'] ?? 0}', icon: Icons.warning_amber, color: userOrange), SummaryTile(label: 'Expiring Soon', value: '${d['expiring_soon'] ?? 0}', icon: Icons.event_busy, color: userRed),
    ]), const SizedBox(height: 18), const Text('Inventory Quick Access', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
    for (final entry in [(UserPage.currentStock, 'Current Stock', Icons.inventory), (UserPage.shelfAging, 'Shelf Stock 3+ Months', Icons.shelves), (UserPage.quantityReview, 'Quantity Review', Icons.fact_check), (UserPage.expiry, 'Expiry Products', Icons.event_busy)])
      UserCard(onTap: () => state.go(entry.$1), child: Row(children: [Icon(entry.$3, color: userBlue), const SizedBox(width: 12), Expanded(child: Text(entry.$2, style: const TextStyle(fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right)])),
  ]))); }
}
