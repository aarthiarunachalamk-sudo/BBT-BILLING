import 'package:flutter/foundation.dart';

import 'admin_api.dart';

class AdminState extends ChangeNotifier {
  AdminState({AdminApi? api}) : api = api ?? AdminApi();

  final AdminApi api;
  int screen = 0;
  int navIndex = 0;
  bool loggedIn = false;
  String staffFilter = 'All';
  String inventoryFilter = 'Low Stock';
  String selectedRole = 'Cashier';
  bool logoutConfirmationVisible = true;
  bool loading = false;
  String? error;
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> purchaseOrders = [];
  List<Map<String, dynamic>> discountApprovals = [];
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> auditLogs = [];
  List<Map<String, dynamic>> rolePermissions = [];
  Map<String, dynamic> storeSettings = {};
  Map<String, dynamic> settingsDraft = {};

  final Map<String, bool> permissions = {
    'Dashboard': true,
    'Products': true,
    'Billing': true,
    'Inventory': true,
    'Discounts': true,
    'Reports': true,
    'Returns': true,
    'Settings': false,
  };
  final Map<String, bool> staffActive = {
    'Rahul Kumar': true,
    'Anita Sharma': true,
    'Vikram Singh': true,
    'Neha Joshi': true,
    'Pooja Mehta': false,
  };
  final Map<String, bool> categoryActive = {
    'Grocery & Staples': true,
    'Fruits & Vegetables': true,
    'Dairy & Bakery': true,
    'Beverages': true,
    'Snacks': true,
    'Household': true,
    'Personal Care': true,
  };

  void go(int value) {
    screen = value.clamp(0, 15);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.login(email, password);
      loggedIn = true;
      screen = 1;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    final responses = await Future.wait<dynamic>([
      api.getMap('dashboard'),
      api.getList('users'),
      api.getList('items'),
      api.getList('categories'),
      api.getList('suppliers'),
      api.getList('purchase-orders'),
      api.getList('discount-approvals'),
      api.getList('invoices'),
      api.getList('audit-logs'),
      api.getList('role-permissions'),
      api.getList('store-settings'),
    ]);
    dashboard = responses[0];
    users = responses[1];
    products = responses[2];
    categories = responses[3];
    suppliers = responses[4];
    purchaseOrders = responses[5];
    discountApprovals = responses[6];
    invoices = responses[7];
    auditLogs = responses[8];
    rolePermissions = responses[9];
    final settings = responses[10] as List<Map<String, dynamic>>;
    storeSettings = settings.isEmpty ? {} : settings.first;
    settingsDraft = Map<String, dynamic>.from(storeSettings);
    _hydrateControls();
    notifyListeners();
  }

  void _hydrateControls() {
    for (final user in users) {
      final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
          .trim();
      if (name.isNotEmpty) staffActive[name] = user['is_active'] == true;
    }
    for (final category in categories) {
      categoryActive[category['name'].toString()] =
          category['is_active'] == true;
    }
    final selected = rolePermissions.where(
      (row) => row['role'] == selectedRole.toLowerCase().replaceAll(' ', '_'),
    );
    if (selected.isNotEmpty) {
      for (final key in permissions.keys) {
        permissions[key] = selected.first[key.toLowerCase()] == true;
      }
    }
  }

  void setNav(int index) {
    navIndex = index;
    screen = switch (index) {
      0 => 1,
      1 => 2,
      2 => 4,
      3 => 14,
      _ => 15,
    };
    notifyListeners();
  }

  void setStaffFilter(String value) {
    staffFilter = value;
    notifyListeners();
  }

  void toggleStaff(String name, bool value) {
    staffActive[name] = value;
    notifyListeners();
    final matching = users.where(
      (row) =>
          '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim() == name,
    );
    if (matching.isNotEmpty) {
      api
          .update('users', matching.first['id'] as int, {'is_active': value})
          .catchError(_captureError);
    }
  }

  void toggleCategory(String name, bool value) {
    categoryActive[name] = value;
    notifyListeners();
    final matching = categories.where((row) => row['name'] == name);
    if (matching.isNotEmpty) {
      api
          .update('categories', matching.first['id'] as int, {
            'is_active': value,
          })
          .catchError(_captureError);
    }
  }

  void togglePermission(String name, bool value) {
    permissions[name] = value;
    notifyListeners();
  }

  void setRole(String value) {
    selectedRole = value;
    _hydrateControls();
    notifyListeners();
  }

  Future<void> savePermissions() async {
    final role = selectedRole.toLowerCase().replaceAll(' ', '_');
    final matching = rolePermissions.where((row) => row['role'] == role);
    final body = {
      for (final entry in permissions.entries)
        entry.key.toLowerCase(): entry.value,
    };
    if (matching.isEmpty) {
      await api.create('role-permissions', {'role': role, ...body});
    } else {
      await api.update('role-permissions', matching.first['id'] as int, body);
    }
    rolePermissions = await api.getList('role-permissions');
    notifyListeners();
  }

  Future<void> decidePurchaseOrder(bool approved) async {
    if (purchaseOrders.isEmpty) return;
    await api.action(
      'purchase-orders',
      purchaseOrders.first['id'] as int,
      'decide',
      {'decision': approved ? 'approved' : 'rejected'},
    );
    purchaseOrders = await api.getList('purchase-orders');
    notifyListeners();
  }

  Future<void> decideDiscount(bool approved) async {
    if (discountApprovals.isEmpty) return;
    await api.action(
      'discount-approvals',
      discountApprovals.first['id'] as int,
      'decide',
      {'decision': approved ? 'approved' : 'rejected'},
    );
    discountApprovals = await api.getList('discount-approvals');
    notifyListeners();
  }

  Future<void> saveStoreSettings(Map<String, dynamic> values) async {
    if (storeSettings.isEmpty) {
      storeSettings = await api.create('store-settings', values);
    } else {
      storeSettings = await api.update(
        'store-settings',
        storeSettings['id'] as int,
        values,
      );
    }
    notifyListeners();
  }

  void updateSetting(String key, dynamic value) {
    settingsDraft[key] = value;
  }

  Future<void> createDemoProduct({required int gst}) async {
    if (categories.isEmpty) {
      throw const ApiException('Create a category before adding products.');
    }
    await api.create('items', {
      'item_type': 'material',
      'name': 'Sunfeast Marie Biscuit 250g',
      'sku': 'SUN-${DateTime.now().millisecondsSinceEpoch}',
      'category': categories.first['id'],
      'unit': 'Pack',
      'purchase_price': '40.00',
      'selling_price': '45.00',
      'tax_percent': '$gst.00',
      'stock_quantity': 20,
      'reorder_level': 20,
      'is_active': true,
    });
    products = await api.getList('items');
    notifyListeners();
  }

  Future<void> approveReturn(String method) async {
    if (invoices.isEmpty ||
        (invoices.first['items'] as List? ?? const []).isEmpty) {
      throw const ApiException('No invoice item is available to return.');
    }
    final invoice = invoices.first;
    final item = (invoice['items'] as List).first as Map<String, dynamic>;
    final returned = await api.create('returns', {
      'invoice': invoice['id'],
      'reason': 'Wrong item purchased',
      'refund_method': switch (method) {
        'Original Payment' => 'original',
        'Store Credit' => 'credit',
        'Replacement' => 'replacement',
        _ => 'cash',
      },
      'items': [
        {'invoice_item': item['id'], 'quantity': 1},
      ],
    });
    await api.action('returns', returned['id'] as int, 'decide', {
      'decision': 'approved',
    });
    products = await api.getList('items');
    notifyListeners();
  }

  Future<void> resendInvoice() async {
    if (invoices.isEmpty) {
      throw const ApiException('No invoice is available to send.');
    }
    await api.create('whatsapp-messages', {
      'invoice': invoices.first['id'],
      'recipient': '+919876543210',
      'message': 'Your invoice ${invoices.first['number']} is ready.',
      'message_type': 'invoice',
    });
  }

  Map<String, dynamic> _captureError(Object exception) {
    error = exception.toString();
    notifyListeners();
    return {};
  }

  void setInventoryFilter(String value) {
    inventoryFilter = value;
    notifyListeners();
  }

  void hideLogoutConfirmation() {
    logoutConfirmationVisible = false;
    notifyListeners();
  }

  void showLogoutConfirmation() {
    logoutConfirmationVisible = true;
    notifyListeners();
  }

  void logout() {
    api.clearSession();
    loggedIn = false;
    screen = 0;
    navIndex = 0;
    logoutConfirmationVisible = true;
    notifyListeners();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
