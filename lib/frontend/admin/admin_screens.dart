import 'package:flutter/material.dart';
import 'admin_state.dart';
import 'admin_widgets.dart';
part 'screens/login_screen.dart';
part 'screens/admin_dashboard_screen.dart';
part 'screens/staff_management_screen.dart';
part 'screens/roles_permissions_screen.dart';
part 'screens/product_management_screen.dart';
part 'screens/add_product_screen.dart';
part 'screens/category_management_screen.dart';
part 'screens/supplier_management_screen.dart';
part 'screens/purchase_order_approval_screen.dart';
part 'screens/inventory_alerts_screen.dart';
part 'screens/sales_dashboard_screen.dart';
part 'screens/discount_approval_screen.dart';
part 'screens/returns_refunds_screen.dart';
part 'screens/whatsapp_invoice_screen.dart';
part 'screens/reports_store_settings_screen.dart';
part 'screens/audit_log_logout_screen.dart';

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
];

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AdminTopBar(
      title: title,
      back: back == null ? null : () => state.go(back!),
      actions: actions,
    ),
    body: SafeArea(top: false, child: child),
    bottomNavigationBar: bottom
        ? AdminBottomBar(selected: state.navIndex, onTap: state.setNav)
        : null,
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
