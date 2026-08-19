import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_state.dart';
import 'admin_widgets.dart';
part 'login_screen.dart';
part 'change_password_screen.dart';
part 'admin_dashboard_screen.dart';
part 'staff_management_screen.dart';
part 'roles_permissions_screen.dart';
part 'product_management_screen.dart';
part 'add_product_screen.dart';
part 'category_management_screen.dart';
part 'supplier_management_screen.dart';
part 'purchase_order_approval_screen.dart';
part 'inventory_alerts_screen.dart';
part 'sales_dashboard_screen.dart';
part 'discount_approval_screen.dart';
part 'returns_refunds_screen.dart';
part 'whatsapp_invoice_screen.dart';
part 'reports_store_settings_screen.dart';
part 'audit_log_logout_screen.dart';

const adminScreenNames = [
  'Admin Login',
  'Admin Dashboard',
  'Staff Management',
  'Roles & Permissions',
  'Product Management',
  'Add Product & GST',
  'Category Management',
  'Supplier Management',
  'Purchase Order Approval',
  'Inventory Alerts',
  'Sales Dashboard',
  'Discount Approval',
  'Returns & Refunds',
  'WhatsApp Invoice Control',
  'Reports & Store Settings',
  'Audit Log & Logout',
  'Change Password',
];

class AdminDestination {
  const AdminDestination(this.screen, this.label, this.icon);

  final int screen;
  final String label;
  final IconData icon;
}

const adminNavigationGroups = <String, List<AdminDestination>>{
  'Overview': [AdminDestination(1, 'Dashboard', Icons.dashboard_outlined)],
  'Team & access': [
    AdminDestination(2, 'Staff Management', Icons.groups_outlined),
    AdminDestination(
      3,
      'Roles & Permissions',
      Icons.admin_panel_settings_outlined,
    ),
  ],
  'Catalog & supply': [
    AdminDestination(4, 'Products', Icons.inventory_2_outlined),
    AdminDestination(5, 'Add Product', Icons.add_box_outlined),
    AdminDestination(6, 'Categories', Icons.category_outlined),
    AdminDestination(7, 'Suppliers', Icons.local_shipping_outlined),
    AdminDestination(
      8,
      'Purchase Orders',
      Icons.shopping_cart_checkout_outlined,
    ),
    AdminDestination(9, 'Inventory Alerts', Icons.inventory_outlined),
  ],
  'Sales & service': [
    AdminDestination(10, 'Sales Dashboard', Icons.analytics_outlined),
    AdminDestination(11, 'Discount Approvals', Icons.percent_outlined),
    AdminDestination(12, 'Returns & Refunds', Icons.assignment_return_outlined),
    AdminDestination(13, 'WhatsApp Invoices', Icons.chat_outlined),
  ],
  'Administration': [
    AdminDestination(14, 'Reports & Settings', Icons.tune_outlined),
    AdminDestination(15, 'Audit Log & Logout', Icons.policy_outlined),
    AdminDestination(16, 'Change Password', Icons.lock_reset_outlined),
  ],
};

class AdminNavigationPanel extends StatelessWidget {
  const AdminNavigationPanel({
    super.key,
    required this.state,
    this.inDrawer = false,
  });

  final AdminState state;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BBT BILLING',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        Text(
                          'ADMIN WORKSPACE',
                          style: TextStyle(
                            color: Color(0xFFAAC6E8),
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inDrawer)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF285487)),
            Expanded(
              child: ListView(
                key: const Key('admin-navigation-list'),
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
                children: [
                  for (final group in adminNavigationGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      child: Text(
                        group.key.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF8EAFD3),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    for (final destination in group.value)
                      _AdminNavigationTile(
                        destination: destination,
                        selected: state.screen == destination.screen,
                        onTap: () {
                          state.go(destination.screen);
                          if (inDrawer) Navigator.of(context).pop();
                        },
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: OutlinedButton.icon(
                onPressed: () {
                  state.go(15);
                  state.showLogoutConfirmation();
                  if (inDrawer) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF4A719E)),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return inDrawer ? Drawer(width: 300, child: content) : content;
  }
}

class _AdminNavigationTile extends StatelessWidget {
  const _AdminNavigationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: const Color(0xFF174E8F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        leading: Icon(
          destination.icon,
          size: 20,
          color: selected ? Colors.white : const Color(0xFFB8CEE7),
        ),
        title: Text(
          destination.label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFD9E6F4),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    ),
  );
}

Widget buildAdminScreen(AdminState state) => switch (state.screen) {
  0 => LoginScreen(state),
  1 => DashboardScreen(state),
  2 => StaffScreen(state),
  3 => RolesScreen(state),
  4 => ProductsScreen(state),
  5 => AddProductScreen(state),
  6 => CategoriesScreen(state),
  7 => SuppliersScreen(state),
  8 => PurchaseOrderScreen(state),
  9 => InventoryAlertsScreen(state),
  10 => SalesDashboardScreen(state),
  11 => DiscountApprovalScreen(state),
  12 => ReturnsScreen(state),
  13 => WhatsAppScreen(state),
  14 => ReportsSettingsScreen(state),
  15 => AuditScreen(state),
  16 => ChangePasswordScreen(state),
  _ => AuditScreen(state),
};

class _AdminPage extends StatelessWidget {
  const _AdminPage({
    required this.state,
    required this.title,
    required this.child,
    this.back,
    this.bottom = true,
    this.actions,
  });
  final AdminState state;
  final String title;
  final Widget child;
  final int? back;
  final bool bottom;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1000;
    final showBottomBar = bottom && MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      drawer: compact && state.loggedIn
          ? AdminNavigationPanel(state: state, inDrawer: true)
          : null,
      appBar: AdminTopBar(
        title: title,
        back: back == null ? null : () => state.go(back!),
        showLeading: compact,
        actions: [
          ...?actions,
          if (state.loggedIn)
            IconButton(
              tooltip: 'Refresh workspace',
              onPressed: state.refreshing
                  ? null
                  : () async {
                      final success = await state.reloadAll();
                      if (!context.mounted) return;
                      showNotice(
                        context,
                        success
                            ? 'Workspace is up to date'
                            : state.error ?? 'Refresh failed',
                      );
                    },
              icon: state.refreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          if (state.loggedIn) _AdminAccountMenu(state: state),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (state.error != null)
              _AdminErrorBanner(
                message: state.error!,
                onDismiss: state.clearError,
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomBar
          ? AdminBottomBar(selected: state.navIndex, onTap: state.setNav)
          : null,
    );
  }
}

class _AdminAccountMenu extends StatelessWidget {
  const _AdminAccountMenu({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Account menu',
    icon: const CircleAvatar(
      radius: 15,
      backgroundColor: Color(0xFFE4EEFC),
      child: Icon(Icons.person_outline_rounded, size: 18, color: navy),
    ),
    onSelected: (value) {
      switch (value) {
        case 'password':
          state.openChangePassword(state.passwordChangeIdentifier);
          return;
        case 'logout':
          state.go(15);
          state.showLogoutConfirmation();
          return;
      }
    },
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'password',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.lock_reset_outlined),
          title: Text('Change password'),
        ),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: 'logout',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.logout_rounded, color: red),
          title: Text('Sign out', style: TextStyle(color: red)),
        ),
      ),
    ],
  );
}

class _AdminErrorBanner extends StatelessWidget {
  const _AdminErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFECEE),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 19, color: red),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8A1720),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message, {this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: muted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
        ],
      ),
    ),
  );
}

String _dateText(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return '—';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _statusText(dynamic value) {
  final text = value?.toString() ?? '';
  return text
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
