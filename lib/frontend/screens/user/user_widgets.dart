import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'user_models.dart';
import 'user_state.dart';

const userNavy = Color(0xFF0B2A5B), userBlue = Color(0xFF123A7A), userGreen = Color(0xFF138A5B);
const userOrange = Color(0xFFF97316), userRed = Color(0xFFDC2626), userBg = Color(0xFFF3F6FC);

class UserShell extends StatelessWidget {
  const UserShell({super.key, required this.state, required this.title, required this.child, this.showBack = false, this.backPage = UserPage.inventory});
  final UserState state;
  final String title;
  final Widget child;
  final bool showBack;
  final UserPage backPage;
  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: showBack ? null : _UserDrawer(state: state),
    appBar: AppBar(
      backgroundColor: userNavy,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: title == 'Store Stock' ? 78 : 58,
      title: title == 'Store Stock'
          ? const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Store Stock', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              Text('Manage & transfer products to shelf', style: TextStyle(fontSize: 12, color: Color(0xFFDCE3EE))),
            ])
          : Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      leading: showBack
          ? IconButton(onPressed: () => state.back(fallback: backPage), icon: const Icon(Icons.arrow_back))
          : Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu_rounded))),
      actions: title == 'Dashboard'
          ? [Padding(padding: const EdgeInsets.only(right: 5), child: Stack(alignment: Alignment.center, children: [IconButton(onPressed: () => state.go(UserPage.expiry), icon: const Icon(Icons.notifications_none_rounded)), const Positioned(right: 8, top: 10, child: CircleAvatar(radius: 4, backgroundColor: userRed))]))]
          : [
              if (title == 'Store Stock') IconButton(tooltip: 'Stock movement history', onPressed: () => state.go(UserPage.stockMovement), icon: const Icon(Icons.history_rounded)),
              IconButton(onPressed: state.loading ? null : state.refresh, icon: const Icon(Icons.refresh)),
            ],
    ),
    body: SafeArea(top: false, child: Column(children: [
      if (state.error != null) Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF1F0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
        child: Row(children: [const Icon(Icons.error_outline_rounded, color: userRed), const SizedBox(width: 10), Expanded(child: Text(state.error!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), TextButton(onPressed: state.refresh, child: const Text('Retry')), IconButton(tooltip: 'Dismiss error', visualDensity: VisualDensity.compact, icon: const Icon(Icons.close), onPressed: () { state.error = null; state.notifyListeners(); })]),
      ),
      Expanded(child: state.loading ? const _UserLoadingSurface() : child),
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

class _UserDrawer extends StatelessWidget {
  const _UserDrawer({required this.state});
  final UserState state;

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          const ListTile(leading: CircleAvatar(backgroundColor: userNavy, child: Icon(Icons.storefront, color: Colors.white)), title: Text('BBT BILLING', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('STAFF WORKSPACE')),
          const Divider(),
          for (final item in [(0, 'Dashboard', Icons.dashboard_outlined), (1, 'Inventory', Icons.inventory_2_outlined), (2, 'Billing', Icons.point_of_sale_outlined), (3, 'Reports', Icons.bar_chart_outlined), (4, 'Profile', Icons.person_outline)])
            ListTile(
              selected: state.navIndex == item.$1,
              leading: Icon(item.$3),
              title: Text(item.$2),
              onTap: () {
                Navigator.pop(context);
                state.setNav(item.$1);
              },
            ),
        ],
      ),
    ),
  );
}

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});
  final Widget child; final VoidCallback? onTap; final EdgeInsets padding;
  @override Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: padding, child: child)),
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

class UserProductImage extends StatelessWidget {
  const UserProductImage({
    super.key,
    required this.imageUrl,
    required this.quantity,
    this.size = 62,
  });

  final String? imageUrl;
  final int quantity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                child: url == null || url.isEmpty
                    ? const Icon(Icons.inventory_2_outlined, color: userBlue)
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.inventory_2_outlined,
                          color: userBlue,
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: quantity > 0 ? userGreen : userRed,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(this.text, {super.key}); final String text;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: userBlue.withValues(alpha: .08), shape: BoxShape.circle), child: const Icon(Icons.inventory_2_outlined, size: 30, color: userBlue)), const SizedBox(height: 14), const Text('Nothing to show yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey, height: 1.35))])));
}

class UserFilterTabs extends StatelessWidget {
  const UserFilterTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, index) {
        final value = values[index];
        final active = value == selected;
        return Semantics(
          selected: active,
          button: true,
          label: '$value filter',
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? userBlue.withValues(alpha: .12) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? userBlue : const Color(0xFFD8E1EC),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (active)
                    const Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(Icons.check_rounded, size: 16, color: userBlue),
                    ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: active ? userBlue : const Color(0xFF475467),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _UserLoadingSurface extends StatelessWidget {
  const _UserLoadingSurface();
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [for (final height in [52.0, 108.0, 108.0, 108.0]) Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(height: height, decoration: BoxDecoration(color: const Color(0xFFE8EEF6), borderRadius: BorderRadius.circular(14))))]);
}

String money(dynamic value) => '₹${(double.tryParse('$value') ?? 0).toStringAsFixed(2)}';
int number(dynamic value) => int.tryParse('$value') ?? 0;
