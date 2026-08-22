import 'package:flutter/material.dart';

import 'user_models.dart';
import 'user_state.dart';

const userNavy = Color(0xFF06245A), userBlue = Color(0xFF075DEB), userGreen = Color(0xFF16A34A);
const userOrange = Color(0xFFF59E0B), userRed = Color(0xFFEF4444), userBg = Color(0xFFF8FAFC);

class UserShell extends StatelessWidget {
  const UserShell({super.key, required this.state, required this.title, required this.child, this.showBack = false});
  final UserState state;
  final String title;
  final Widget child;
  final bool showBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: userNavy, foregroundColor: Colors.white,
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      leading: showBack ? IconButton(onPressed: () => state.go(UserPage.inventory), icon: const Icon(Icons.arrow_back)) : null,
      actions: [IconButton(onPressed: state.loading ? null : state.refresh, icon: const Icon(Icons.refresh))],
    ),
    body: SafeArea(top: false, child: Column(children: [
      if (state.error != null) Material(color: const Color(0xFFFFE8E8), child: ListTile(
        dense: true, leading: const Icon(Icons.error_outline, color: userRed), title: Text(state.error!),
        trailing: IconButton(icon: const Icon(Icons.close), onPressed: () { state.error = null; state.notifyListeners(); }),
      )),
      Expanded(child: state.loading ? const Center(child: CircularProgressIndicator()) : child),
    ])),
    bottomNavigationBar: NavigationBar(
      selectedIndex: state.navIndex, onDestinationSelected: state.setNav,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
        NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Billing'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
  );
}

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});
  final Widget child; final VoidCallback? onTap; final EdgeInsets padding;
  @override Widget build(BuildContext context) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
    child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: Padding(padding: padding, child: child)),
  );
}

class SummaryTile extends StatelessWidget {
  const SummaryTile({super.key, required this.label, required this.value, required this.icon, required this.color});
  final String label, value; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => UserCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)), const SizedBox(height: 12),
    Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
  ]));
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key}); final String status;
  @override Widget build(BuildContext context) { final s = status.toLowerCase(); final c = s.contains('out') || s.contains('expired') || s.contains('overdue') ? userRed : s.contains('low') || s.contains('review') ? userOrange : userGreen;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(status.replaceAll('_', ' '), style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)));
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.text, {super.key}); final String text;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox_outlined, size: 48, color: Colors.blueGrey), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey))])));
}

String money(dynamic value) => '₹${(double.tryParse('$value') ?? 0).toStringAsFixed(2)}';
int number(dynamic value) => int.tryParse('$value') ?? 0;
