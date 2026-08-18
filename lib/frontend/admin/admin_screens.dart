import 'package:flutter/material.dart';

import 'admin_state.dart';
import 'admin_widgets.dart';

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

class LoginScreen extends StatefulWidget {
  const LoginScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;
  bool remember = false;
  final emailController = TextEditingController(text: 'aarthi');
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AdminTopBar(title: 'Admin Login'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Welcome Admin',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to access admin panel',
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: emailController,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Username or Email'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: remember,
                onChanged: (v) => setState(() => remember = v ?? false),
              ),
              const Text('Remember me', style: TextStyle(fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    showNotice(context, 'Password reset link sent'),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          if (widget.state.error != null) ...[
            Text(
              widget.state.error!,
              style: const TextStyle(color: red, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
          widget.state.loading
              ? const Center(child: CircularProgressIndicator())
              : PrimaryAction(
                  'Login',
                  onPressed: () async {
                    final success = await widget.state.login(
                      emailController.text.trim(),
                      passwordController.text,
                    );
                    if (!success && context.mounted) {
                      showNotice(context, widget.state.error ?? 'Login failed');
                    }
                  },
                ),
          const SizedBox(height: 40),
          const Icon(Icons.lock, color: green, size: 25),
          const SizedBox(height: 7),
          const Text(
            'Secure admin access',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const Text(
            'for authorized personnel only',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    ),
  );
}

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
              'Estimated margin',
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

class StaffScreen extends StatelessWidget {
  const StaffScreen(this.state, {super.key});
  final AdminState state;
  static const info = {
    'Rahul Kumar': ['admin@hypermart.com', 'Admin'],
    'Anita Sharma': ['anita@supermart.com', 'Cashier'],
    'Vikram Singh': ['vikram@supermart.com', 'Cashier'],
    'Neha Joshi': ['neha@supermart.com', 'Inventory Manager'],
    'Pooja Mehta': ['pooja@supermart.com', 'Cashier'],
  };
  static String userName(Map<String, dynamic> user) {
    final fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    return fullName.isEmpty ? user['username'].toString() : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final staffInfo = state.users.isEmpty
        ? info
        : <String, List<String>>{
            for (final user in state.users)
              userName(user): [
                user['email']?.toString() ?? '',
                user['role']?.toString().replaceAll('_', ' ') ?? '',
              ],
          };
    final names = staffInfo.keys
        .where(
          (n) =>
              state.staffFilter == 'All' ||
              (state.staffFilter == 'Active') == state.staffActive[n]!,
        )
        .toList();
    return _AdminPage(
      state: state,
      title: 'Staff Management',
      back: 1,
      actions: [
        IconButton(
          onPressed: () => state.go(3),
          icon: const Icon(Icons.admin_panel_settings_outlined),
        ),
      ],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14),
            child: SearchBox('Search users by name, role or email'),
          ),
          Row(
            children: ['All', 'Active', 'Inactive']
                .map(
                  (f) => Expanded(
                    child: InkWell(
                      onTap: () => state.setStaffFilter(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: state.staffFilter == f ? blue : line,
                              width: state.staffFilter == f ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '$f (${f == 'All'
                              ? 12
                              : f == 'Active'
                              ? 9
                              : 3})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: state.staffFilter == f ? blue : muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: names.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final name = names[i];
                final details = staffInfo[name]!;
                final active = state.staffActive[name] ?? true;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 3),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFDCEAFF),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    details[0],
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              details[1],
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 9, color: green),
                            ),
                            Text(
                              active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 9,
                                color: active ? green : red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: active,
                        onChanged: (v) => state.toggleStaff(name, v),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: PrimaryAction(
              'Add User',
              icon: Icons.add,
              onPressed: () => state.go(3),
            ),
          ),
        ],
      ),
    );
  }
}

class RolesScreen extends StatelessWidget {
  const RolesScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Roles & Permissions',
    back: 2,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Role',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                initialValue: state.selectedRole,
                items: ['Cashier', 'Admin', 'Inventory Manager']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) state.setRole(v);
                },
              ),
              const SizedBox(height: 22),
              const Text(
                'Permissions',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...state.permissions.entries.map(
                (e) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: Icon(
                    _permissionIcon(e.key),
                    size: 19,
                    color: muted,
                  ),
                  title: Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: e.value,
                  onChanged: (v) => state.togglePermission(e.key, v ?? false),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            'Save Permissions',
            onPressed: () async {
              try {
                await state.savePermissions();
                if (context.mounted) {
                  showNotice(
                    context,
                    '${state.selectedRole} permissions saved',
                  );
                }
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
          ),
        ),
      ],
    ),
  );
}

IconData _permissionIcon(String value) => switch (value) {
  'Dashboard' => Icons.dashboard_outlined,
  'Products' => Icons.inventory_2_outlined,
  'Billing' => Icons.receipt_long_outlined,
  'Inventory' => Icons.warehouse_outlined,
  'Discounts' => Icons.discount_outlined,
  'Reports' => Icons.assessment_outlined,
  'Returns' => Icons.assignment_return_outlined,
  _ => Icons.settings_outlined,
};

class ProductsScreen extends StatelessWidget {
  const ProductsScreen(this.state, {super.key});
  final AdminState state;
  static const products = [
    [
      '🥫',
      'Aashirvaad Atta 5kg',
      'SKU: AASH5000  ·  MRP: ₹240.00',
      '₹ 215.00',
      '120',
      'In Stock',
    ],
    [
      '🧴',
      'Fortune Oil 1L',
      'SKU: FORT-OIL1L  ·  MRP: ₹160.00',
      '₹ 140.00',
      '85',
      'In Stock',
    ],
    [
      '🥛',
      'Amul Fresh Milk 1L',
      'SKU: AMULMILK-1L  ·  MRP: ₹60.00',
      '₹ 60.00',
      '45',
      'In Stock',
    ],
    [
      '🍵',
      'Tata Salt 1kg',
      'SKU: TATA-SALT-1KG  ·  MRP: ₹20.00',
      '₹ 18.00',
      '0',
      'Out of Stock',
    ],
  ];
  List<List<String>> get displayProducts => state.products.isEmpty
      ? products
      : state.products.map((p) {
          final status = (p['stock_status'] ?? '').toString();
          return <String>[
            '📦',
            p['name'].toString(),
            'SKU: ${p['sku']} · ${p['category_name'] ?? ''}',
            _money(p['selling_price']),
            '${p['stock_quantity'] ?? 0}',
            status == 'out_of_stock'
                ? 'Out of Stock'
                : status == 'low_stock'
                ? 'Low Stock'
                : 'In Stock',
          ];
        }).toList();
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Product Management',
    back: 1,
    actions: [
      PopupMenuButton<int>(
        iconColor: Colors.white,
        onSelected: state.go,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 6, child: Text('Categories')),
          PopupMenuItem(value: 7, child: Text('Suppliers')),
          PopupMenuItem(value: 9, child: Text('Inventory alerts')),
        ],
      ),
    ],
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: SearchBox(
            'Search by name, SKU or barcode',
            trailing: Icons.filter_alt_outlined,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayProducts.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final p = displayProducts[i];
              final out = p[5] == 'Out of Stock';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: Container(
                  width: 44,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: page,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(p[0], style: const TextStyle(fontSize: 26)),
                ),
                title: Text(
                  p[1],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${p[2]}\nGST: ${i == 3 ? '0%' : '5%'}     Stock: ${p[4]}',
                  style: const TextStyle(fontSize: 9, height: 1.5),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p[3],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      p[5],
                      style: TextStyle(
                        fontSize: 9,
                        color: out ? red : green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: PrimaryAction(
            'Add Product',
            icon: Icons.add,
            onPressed: () => state.go(5),
          ),
        ),
      ],
    ),
  );
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int gst = 12;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Add Product',
    back: 4,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: 'Sunfeast Marie Biscuit 250g',
                decoration: const InputDecoration(labelText: 'Product Name *'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Barcode / SKU',
                  hintText: 'Scan or enter barcode / SKU',
                  suffixIcon: Icon(Icons.qr_code_scanner, color: blue),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: 'Snacks',
                decoration: const InputDecoration(labelText: 'Category *'),
                items: ['Snacks', 'Grocery & Staples', 'Beverages']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '40.00',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (₹)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: '50.00',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'MRP (₹)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: '45.00',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (₹) *',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GST Slab *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [0, 5, 12, 18, 28]
                    .map(
                      (v) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ChoiceChip(
                            label: Text(
                              '$v%',
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: gst == v,
                            onSelected: (_) => setState(() => gst = v),
                            selectedColor: blue,
                            labelStyle: TextStyle(
                              color: gst == v ? Colors.white : ink,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: 'Pack',
                      decoration: const InputDecoration(labelText: 'Unit *'),
                      items: ['Pack', 'Piece', 'Kg']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: '20',
                      decoration: const InputDecoration(
                        labelText: 'Minimum Stock *',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            'Save Product',
            onPressed: () async {
              try {
                await widget.state.createDemoProduct(gst: gst);
                if (context.mounted) {
                  showNotice(context, 'Product saved successfully');
                  widget.state.go(4);
                }
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
          ),
        ),
      ],
    ),
  );
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(this.state, {super.key});
  final AdminState state;
  static const details = {
    'Grocery & Staples': ['🌾', '120 Products'],
    'Fruits & Vegetables': ['🍎', '85 Products'],
    'Dairy & Bakery': ['🥛', '60 Products'],
    'Beverages': ['🥤', '45 Products'],
    'Snacks': ['🍿', '70 Products'],
    'Household': ['🧼', '70 Products'],
    'Personal Care': ['🧴', '55 Products'],
  };
  Map<String, List<String>> get displayCategories => state.categories.isEmpty
      ? details
      : {
          for (final category in state.categories)
            category['name'].toString(): [
              '📦',
              '${category['product_count'] ?? 0} Products',
            ],
        };
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Category Management',
    back: 4,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: SearchBox('Search categories'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayCategories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final name = displayCategories.keys.elementAt(i);
              final d = displayCategories[name]!;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 3),
                leading: Text(d[0], style: const TextStyle(fontSize: 24)),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(d[1], style: const TextStyle(fontSize: 10)),
                trailing: Switch(
                  value: state.categoryActive[name]!,
                  onChanged: (v) => state.toggleCategory(name, v),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: PrimaryAction(
            'Add Category',
            icon: Icons.add,
            onPressed: () => showNotice(context, 'New category form opened'),
          ),
        ),
      ],
    ),
  );
}

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen(this.state, {super.key});
  final AdminState state;
  static const suppliers = [
    ['Balaji Distributors', '27AACCB1234F1Z5', '9876543210', '₹ 24,500.00'],
    ['Shree Traders', '07CCAZQ0002G2Z1', '9911122233', '₹ 18,750.00'],
    ['Fresh Foods Pvt. Ltd.', '01AABCPQ4567H1Z2', '9877754456', '₹ 9,350.00'],
    ['Quality Supplies', '19BBRTY9001F2Z3', '9355066670', '₹ 5,120.00'],
  ];
  List<List<String>> get displaySuppliers => state.suppliers.isEmpty
      ? suppliers
      : state.suppliers
            .map(
              (s) => <String>[
                s['name'].toString(),
                s['gstin']?.toString() ?? '',
                s['phone']?.toString() ?? '',
                '₹ 0.00',
              ],
            )
            .toList();
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Supplier Management',
    back: 4,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: SearchBox('Search suppliers'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displaySuppliers.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final s = displaySuppliers[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEAF2FF),
                  child: Icon(
                    i.isEven ? Icons.apartment : Icons.storefront,
                    color: blue,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s[0],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      'Active',
                      style: TextStyle(fontSize: 9, color: green),
                    ),
                  ],
                ),
                subtitle: Text(
                  'GSTIN: ${s[1]}\nPhone: ${s[2]}\nOutstanding: ${s[3]}',
                  style: const TextStyle(fontSize: 9, height: 1.5),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Add Supplier',
                  icon: Icons.add,
                  onPressed: () =>
                      showNotice(context, 'New supplier form opened'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: PrimaryAction(
                  'View Ledger',
                  outlined: true,
                  onPressed: () => state.go(8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PurchaseOrderScreen extends StatelessWidget {
  const PurchaseOrderScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'PO Approval',
    back: 7,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              LabeledValue('PO Number', 'PO-2025-0054'),
              LabeledValue('Supplier', 'Balaji Distributors'),
              LabeledValue('Order Date', '14 May 2025'),
              SizedBox(height: 12),
              _TableHeader(['Product', 'Qty', 'Rate (₹)', 'Amount (₹)']),
              _TableRow(['Aashirvaad Atta 5kg', '50', '210.00', '10,500.00']),
              _TableRow(['Fortune Oil 1L', '30', '150.00', '4,500.00']),
              _TableRow(['Tata Salt 1kg', '100', '16.00', '1,600.00']),
              Divider(height: 24),
              LabeledValue('Taxable Amount', '₹ 16,600.00'),
              LabeledValue('CGST (6%)', '₹ 996.00'),
              LabeledValue('SGST (6%)', '₹ 996.00'),
              Divider(),
              LabeledValue('Grand Total', '₹ 18,592.00'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Approve',
                  color: green,
                  onPressed: () async {
                    await state.decidePurchaseOrder(true);
                    if (context.mounted) {
                      showNotice(context, 'Purchase order approved');
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryAction(
                  'Reject',
                  color: red,
                  onPressed: () async {
                    await state.decidePurchaseOrder(false);
                    if (context.mounted) {
                      showNotice(context, 'Purchase order rejected');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.values);
  final List<String> values;
  @override
  Widget build(BuildContext context) => Container(
    color: page,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: values
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              flex: e.key == 0 ? 3 : 2,
              child: Text(
                e.value,
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _TableRow extends StatelessWidget {
  const _TableRow(this.values, {this.highlight = false});
  final List<String> values;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: values
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              flex: e.key == 0 ? 3 : 2,
              child: Text(
                e.value,
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right,
                style: TextStyle(
                  fontSize: 9,
                  color: highlight && e.key > 0 ? red : ink,
                  fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class InventoryAlertsScreen extends StatelessWidget {
  const InventoryAlertsScreen(this.state, {super.key});
  final AdminState state;
  static const rows = [
    ['Amul Butter 100g', '5', '20', '25 Jun 2025'],
    ['Britannia Bread 400g', '8', '20', '22 May 2025'],
    ['Nescafe 200g', '10', '25', '10 Jun 2025'],
    ['Surf Excel 1kg', '7', '15', '15 May 2025'],
    ['Colgate Toothpaste 100g', '4', '10', '–'],
    ['Parle-G 200g', '0', '20', '–'],
  ];
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Inventory Alerts',
    back: 4,
    bottom: false,
    child: Column(
      children: [
        Row(
          children: ['Low Stock', 'Expiring', 'Out of Stock']
              .map(
                (f) => Expanded(
                  child: InkWell(
                    onTap: () => state.setInventoryFilter(f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: state.inventoryFilter == f ? blue : line,
                            width: state.inventoryFilter == f ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        f,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: state.inventoryFilter == f ? blue : muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: _TableHeader(['Item', 'Current', 'Min. Stock', 'Expiry']),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: rows.map((r) => _TableRow(r, highlight: true)).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Reorder Selected (3)',
                  onPressed: () =>
                      showNotice(context, 'Reorder request created'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryAction(
                  'Adjust Stock',
                  outlined: true,
                  onPressed: () =>
                      showNotice(context, 'Stock adjustment opened'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: '14 May 2025 - 14 May 2025',
    back: 1,
    bottom: false,
    actions: [
      IconButton(
        onPressed: () {},
        icon: const Icon(Icons.calendar_month_outlined),
      ),
    ],
    child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: const [
            _Metric('Total Sales', '₹ 45,320', '↑ 8.5%', green),
            _Metric('Bills', '256', '↑ 6.3%', green),
            _Metric('Avg. Bill Value', '₹ 177.03', '', muted),
            _Metric('Profit', '₹ 12,850', '↑ 7.2%', green),
            _Metric('Returns', '₹ 1,250', '↓ 2.1%', red),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Sales Trend (Last 7 Days)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const SectionCard(
          child: SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _SalesChartPainter(),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '08 May       10 May       12 May       14 May',
                    style: TextStyle(fontSize: 8, color: muted),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Payment Method Breakup',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const Row(
            children: [
              Expanded(
                flex: 40,
                child: ColoredBox(color: blue, child: SizedBox(height: 18)),
              ),
              Expanded(
                flex: 35,
                child: ColoredBox(color: green, child: SizedBox(height: 18)),
              ),
              Expanded(
                flex: 15,
                child: ColoredBox(
                  color: Color(0xFF8B5CC7),
                  child: SizedBox(height: 18),
                ),
              ),
              Expanded(
                flex: 10,
                child: ColoredBox(
                  color: Colors.orange,
                  child: SizedBox(height: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Cash\n40%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'UPI\n35%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'Card\n15%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
            Text(
              'Other\n10%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final pts = [
      const Offset(.02, .76),
      const Offset(.15, .42),
      const Offset(.28, .28),
      const Offset(.41, .48),
      const Offset(.54, .31),
      const Offset(.67, .52),
      const Offset(.80, .39),
      const Offset(.88, .17),
      const Offset(.98, .25),
    ];
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = blue
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (final point in pts) {
      final p = Offset(point.dx * size.width, point.dy * size.height);
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiscountApprovalScreen extends StatelessWidget {
  const DiscountApprovalScreen(this.state, {super.key});
  final AdminState state;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Discount Approval',
    back: 1,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              LabeledValue('Bill Number', 'BILL-2025-0145'),
              LabeledValue('Cashier', 'Anita Sharma'),
              LabeledValue('Customer', 'Walk-in Customer'),
              LabeledValue('Bill Amount', '₹ 3,650.00'),
              LabeledValue('Requested Discount', '18%'),
              LabeledValue('Discount Amount', '₹ 657.00'),
              LabeledValue('Reason', 'Festival offer for regular customer'),
              SizedBox(height: 22),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Policy',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Cashier Limit: 10%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Discount above 10% require admin approval.',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Approve',
                  color: green,
                  onPressed: () async {
                    await state.decideDiscount(true);
                    if (context.mounted) {
                      showNotice(context, 'Discount approved');
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: PrimaryAction(
                  'Reject',
                  color: red,
                  onPressed: () async {
                    await state.decideDiscount(false);
                    if (context.mounted) {
                      showNotice(context, 'Discount rejected');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  String method = 'Cash';
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Returns & Refunds',
    back: 14,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SearchBox('Search invoice'),
              const SizedBox(height: 10),
              const Text(
                'BILL-2025-0138',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 15),
              const Text(
                'Items Returned',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const _TableHeader(['Item', 'Qty', 'Amount (₹)']),
              const _TableRow(['Fortune Oil 1L', '1', '160.00']),
              const _TableRow(['Tata Salt 1kg', '1', '18.00']),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: 'Wrong item purchased',
                decoration: const InputDecoration(labelText: 'Return Reason'),
                items: ['Wrong item purchased', 'Damaged item', 'Expired item']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: '178.00',
                decoration: const InputDecoration(
                  labelText: 'Refund Amount (₹)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Refund Method',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              ...[
                'Cash',
                'Original Payment',
                'Store Credit',
                'Replacement',
              ].map(
                (v) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () => setState(() => method = v),
                  leading: Icon(
                    method == v
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: method == v ? blue : muted,
                    size: 20,
                  ),
                  title: Text(v, style: const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            'Approve Refund',
            onPressed: () async {
              try {
                await widget.state.approveReturn(method);
                if (context.mounted) {
                  showNotice(context, 'Refund approved via $method');
                }
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
          ),
        ),
      ],
    ),
  );
}

class WhatsAppScreen extends StatelessWidget {
  const WhatsAppScreen(this.state, {super.key});
  final AdminState state;
  static const invoices = [
    ['BILL-2025-0145', '+91 98765 43210', '14 May, 11:20 AM', 'Sent'],
    ['BILL-2025-0144', '+91 97654 32109', '14 May, 11:05 AM', 'Delivered'],
    ['BILL-2025-0143', '+91 96543 21098', '14 May, 10:55 AM', 'Read'],
    ['BILL-2025-0142', '+91 95432 10987', '14 May, 10:45 AM', 'Pending'],
  ];
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'WhatsApp Invoice Control',
    back: 14,
    bottom: false,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Invoice History',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: invoices.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final x = invoices[i];
              final color = x[3] == 'Pending' ? Colors.orange : green;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: navy),
                title: Text(
                  x[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(x[1], style: const TextStyle(fontSize: 10)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      x[3],
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      x[2],
                      style: const TextStyle(fontSize: 9, color: muted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Resend Invoice',
                  outlined: true,
                  onPressed: () async {
                    try {
                      await state.resendInvoice();
                      if (context.mounted) {
                        showNotice(context, 'Invoice queued for WhatsApp');
                      }
                    } catch (error) {
                      if (context.mounted) {
                        showNotice(context, error.toString());
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryAction(
                  'Download PDF',
                  outlined: true,
                  onPressed: () => showNotice(context, 'PDF downloaded'),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: Text(
            'WhatsApp consent must be enabled.',
            style: TextStyle(fontSize: 9, color: muted),
          ),
        ),
      ],
    ),
  );
}

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
            value.replaceAll('₹', '').trim(),
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

class AuditScreen extends StatelessWidget {
  const AuditScreen(this.state, {super.key});
  final AdminState state;
  static const logs = [
    ['Rahul Kumar', 'Login', 'Auth', '14 May, 10:03 AM', '192.168.1.10'],
    [
      'Rahul Kumar',
      'Approved PO',
      'Purchase',
      '14 May, 10:24 AM',
      '192.168.1.10',
    ],
    [
      'Anita Sharma',
      'Discount Approved',
      'Discounts',
      '14 May, 10:15 AM',
      '192.168.1.12',
    ],
    [
      'Vikram Singh',
      'Stock Adjusted',
      'Inventory',
      '14 May, 10:10 AM',
      '192.168.1.11',
    ],
    [
      'Neha Joshi',
      'Added Product',
      'Products',
      '14 May, 10:02 AM',
      '192.168.1.10',
    ],
    ['Rahul Kumar', 'Logout', 'Auth', '14 May, 10:00 AM', '192.168.1.10'],
  ];
  List<List<String>> get displayLogs => state.auditLogs.isEmpty
      ? logs
      : state.auditLogs
            .map(
              (log) => <String>[
                (log['user_name']?.toString().trim().isNotEmpty ?? false)
                    ? log['user_name'].toString()
                    : 'System',
                log['action']?.toString() ?? '',
                log['module']?.toString() ?? '',
                log['created_at']
                        ?.toString()
                        .replaceFirst('T', ' ')
                        .split('.')
                        .first ??
                    '',
                log['ip_address']?.toString() ?? '',
              ],
            )
            .toList();
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Audit Log',
    back: 14,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 590,
              child: Column(
                children: [
                  Container(
                    color: page,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 95,
                          child: Text('User', style: _tableStyle),
                        ),
                        SizedBox(
                          width: 105,
                          child: Text('Action', style: _tableStyle),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text('Module', style: _tableStyle),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text('Date & Time', style: _tableStyle),
                        ),
                        Expanded(
                          child: Text('IP / Device', style: _tableStyle),
                        ),
                      ],
                    ),
                  ),
                  ...displayLogs.map(
                    (x) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: line)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 95,
                            child: Text(
                              x[0],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          SizedBox(
                            width: 105,
                            child: Text(
                              x[1],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              x[2],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: Text(
                              x[3],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              x[4],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              PrimaryAction(
                'Logout',
                color: red,
                onPressed: state.showLogoutConfirmation,
              ),
              if (state.logoutConfirmationVisible) ...[
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Confirm Logout',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: state.hideLogoutConfirmation,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                      const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryAction(
                              'Cancel',
                              outlined: true,
                              color: muted,
                              onPressed: state.hideLogoutConfirmation,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryAction(
                              'Logout',
                              color: red,
                              onPressed: state.logout,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

const _tableStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.w800);
