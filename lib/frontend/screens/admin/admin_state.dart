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
  String productQuery = '';
  String productStockFilter = 'All';
  String staffQuery = '';
  String categoryQuery = '';
  String supplierQuery = '';
  String selectedRole = 'Cashier';
  bool logoutConfirmationVisible = false;
  bool loggingOut = false;
  bool loading = false;
  bool refreshing = false;
  bool decidingPurchaseOrder = false;
  bool decidingDiscount = false;
  String? error;
  String passwordChangeIdentifier = '';
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> purchaseOrders = [];
  List<Map<String, dynamic>> discountApprovals = [];
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> whatsappMessages = [];
  List<Map<String, dynamic>> auditLogs = [];
  List<Map<String, dynamic>> rolePermissions = [];
  Map<String, dynamic> storeSettings = {};
  Map<String, dynamic> settingsDraft = {};

  final Map<String, bool> permissions = {
    'Dashboard': false,
    'Products': false,
    'Billing': false,
    'Inventory': false,
    'Discounts': false,
    'Reports': false,
    'Returns': false,
    'Settings': false,
  };
  final Map<String, bool> staffActive = {};
  final Map<String, bool> categoryActive = {};

  void go(int value) {
    var destination = value.clamp(0, 16);
    if (!loggedIn && destination != 0 && destination != 16) {
      destination = 0;
    }
    screen = destination;
    navIndex = switch (destination) {
      1 => 0,
      2 || 3 => 1,
      >= 4 && <= 9 => 2,
      >= 10 && <= 13 => 3,
      >= 14 => 4,
      _ => navIndex,
    };
    notifyListeners();
  }

  void openChangePassword(String identifier) {
    passwordChangeIdentifier = identifier;
    error = null;
    screen = 16;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String identifier,
    required String currentPassword,
    required String newPassword,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.changePassword(
        identifier: identifier,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
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

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.login(email, password);
      loggedIn = true;
      passwordChangeIdentifier = email;
      screen = 1;
      await refreshAll();
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
      api.getList('whatsapp-messages'),
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
    whatsappMessages = responses[11];
    storeSettings = settings.isEmpty ? {} : settings.first;
    settingsDraft = Map<String, dynamic>.from(storeSettings);
    if (rolePermissions.isNotEmpty) {
      selectedRole = _roleLabel(rolePermissions.first['role'].toString());
    }
    _hydrateControls();
    notifyListeners();
  }

  Future<bool> reloadAll() async {
    if (refreshing) return false;
    refreshing = true;
    error = null;
    notifyListeners();
    try {
      await refreshAll();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
      return false;
    } finally {
      refreshing = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    error = null;
    try {
      dashboard = await api.getMap('dashboard');
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
    }
    notifyListeners();
  }

  void _hydrateControls() {
    staffActive.clear();
    categoryActive.clear();
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

  List<String> get availableRoles =>
      rolePermissions.map((row) => _roleLabel(row['role'].toString())).toList();

  String _roleLabel(String value) => value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

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
    final matching = users.where(
      (row) =>
          '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim() == name,
    );
    if (matching.isNotEmpty) {
      final user = matching.first;
      final previous = user['is_active'] == true;
      staffActive[name] = value;
      user['is_active'] = value;
      error = null;
      notifyListeners();
      api.update('users', user['id'] as int, {'is_active': value}).catchError((
        Object exception,
      ) {
        staffActive[name] = previous;
        user['is_active'] = previous;
        return _captureError(exception);
      });
    }
  }

  void toggleCategory(String name, bool value) {
    final matching = categories.where((row) => row['name'] == name);
    if (matching.isNotEmpty) {
      final category = matching.first;
      final previous = category['is_active'] == true;
      categoryActive[name] = value;
      category['is_active'] = value;
      error = null;
      notifyListeners();
      api
          .update('categories', category['id'] as int, {'is_active': value})
          .catchError((Object exception) {
            categoryActive[name] = previous;
            category['is_active'] = previous;
            return _captureError(exception);
          });
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
    if (decidingPurchaseOrder) return;
    final pending = purchaseOrders.where((row) => row['status'] == 'pending');
    if (pending.isEmpty) {
      throw const ApiException('No pending purchase order is available.');
    }
    decidingPurchaseOrder = true;
    notifyListeners();
    try {
      await api.action(
        'purchase-orders',
        pending.first['id'] as int,
        'decide',
        {'decision': approved ? 'approved' : 'rejected'},
      );
      purchaseOrders = await api.getList('purchase-orders');
      dashboard = await api.getMap('dashboard');
    } finally {
      decidingPurchaseOrder = false;
      notifyListeners();
    }
  }

  Future<void> decideDiscount(bool approved) async {
    if (decidingDiscount) return;
    final pending = discountApprovals.where(
      (row) => row['status'] == 'pending',
    );
    if (pending.isEmpty) {
      throw const ApiException('No pending discount approval is available.');
    }
    decidingDiscount = true;
    notifyListeners();
    try {
      await api.action(
        'discount-approvals',
        pending.first['id'] as int,
        'decide',
        {'decision': approved ? 'approved' : 'rejected'},
      );
      discountApprovals = await api.getList('discount-approvals');
      dashboard = await api.getMap('dashboard');
    } finally {
      decidingDiscount = false;
      notifyListeners();
    }
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

  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> values,
  ) async {
    final created = await api.create('items', values);
    products = [
      created,
      ...products.where((product) => product['id'] != created['id']),
    ];
    productQuery = '';
    try {
      dashboard = await api.getMap('dashboard');
    } on ApiException {
      // The product is already saved; dashboard can refresh on the next visit.
    }
    notifyListeners();
    return created;
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    final normalized = name.trim().toLowerCase();
    final existing = categories.where(
      (category) =>
          category['name']?.toString().trim().toLowerCase() == normalized,
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }
    try {
      await api.create('categories', {'name': name.trim(), 'is_active': true});
    } on ApiException catch (exception) {
      if (!exception.message.toLowerCase().contains('already exists')) {
        rethrow;
      }
    }
    categories = await api.getList('categories');
    _hydrateControls();
    notifyListeners();
    final saved = categories.where(
      (category) =>
          category['name']?.toString().trim().toLowerCase() == normalized,
    );
    if (saved.isEmpty) {
      throw const ApiException('Category could not be loaded after saving.');
    }
    return saved.first;
  }

  Future<void> createSupplier(Map<String, dynamic> values) async {
    await api.create('suppliers', values);
    suppliers = await api.getList('suppliers');
    notifyListeners();
  }

  Future<void> createUser(Map<String, dynamic> values) async {
    await api.create('users', values);
    users = await api.getList('users');
    _hydrateControls();
    notifyListeners();
  }

  Future<void> adjustStock(int itemId, int quantity) async {
    await api.action('items', itemId, 'adjust_stock', {
      'quantity': quantity,
      'transaction_type': 'adjustment',
    });
    products = await api.getList('items');
    dashboard = await api.getMap('dashboard');
    notifyListeners();
  }

  Future<void> createReorder(int itemId) async {
    final matches = products.where((product) => product['id'] == itemId);
    if (matches.isEmpty) throw const ApiException('Product not found.');
    final product = matches.first;
    final supplierId = product['supplier'];
    if (supplierId == null) {
      throw const ApiException('Assign a supplier to this product first.');
    }
    final stock = int.tryParse(product['stock_quantity'].toString()) ?? 0;
    final reorder = int.tryParse(product['reorder_level'].toString()) ?? 1;
    final required = reorder - stock;
    await api.create('purchase-orders', {
      'supplier': supplierId,
      'status': 'pending',
      'items': [
        {
          'item': itemId,
          'quantity': required > 0 ? required : reorder,
          'unit_cost': product['purchase_price'],
          'tax_percent': product['tax_percent'],
        },
      ],
    });
    purchaseOrders = await api.getList('purchase-orders');
    dashboard = await api.getMap('dashboard');
    notifyListeners();
  }

  Future<void> approveReturn({
    required int invoiceId,
    required int invoiceItemId,
    required int quantity,
    required String reason,
    required String method,
  }) async {
    final returned = await api.create('returns', {
      'invoice': invoiceId,
      'reason': reason,
      'refund_method': method,
      'items': [
        {'invoice_item': invoiceItemId, 'quantity': quantity},
      ],
    });
    await api.action('returns', returned['id'] as int, 'decide', {
      'decision': 'approved',
    });
    products = await api.getList('items');
    notifyListeners();
  }

  Future<void> resendInvoice([Map<String, dynamic>? selectedInvoice]) async {
    if (invoices.isEmpty) {
      throw const ApiException('No invoice is available to send.');
    }
    final invoice = selectedInvoice ?? invoices.first;
    final recipient = invoice['client_mobile']?.toString() ?? '';
    if (recipient.isEmpty) {
      throw const ApiException(
        'The selected invoice has no customer mobile number.',
      );
    }
    await api.create('whatsapp-messages', {
      'invoice': invoice['id'],
      'recipient': recipient,
      'message': 'Your invoice ${invoice['number']} is ready.',
      'message_type': 'invoice',
    });
    whatsappMessages = await api.getList('whatsapp-messages');
    notifyListeners();
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

  void setProductQuery(String value) {
    productQuery = value;
    notifyListeners();
  }

  void setProductStockFilter(String value) {
    productStockFilter = value;
    notifyListeners();
  }

  void setStaffQuery(String value) {
    staffQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  void setCategoryQuery(String value) {
    categoryQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  void setSupplierQuery(String value) {
    supplierQuery = value.trim().toLowerCase();
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

  Future<void> logout() async {
    if (loggingOut) return;
    loggingOut = true;
    error = null;
    notifyListeners();
    try {
      await api.logout();
    } catch (_) {
      // Local logout must still complete if the server is temporarily offline.
    } finally {
      api.clearSession();
      loggedIn = false;
      screen = 0;
      navIndex = 0;
      logoutConfirmationVisible = false;
      loggingOut = false;
      refreshing = false;
      decidingPurchaseOrder = false;
      decidingDiscount = false;
      staffFilter = 'All';
      inventoryFilter = 'Low Stock';
      productQuery = '';
      productStockFilter = 'All';
      staffQuery = '';
      categoryQuery = '';
      supplierQuery = '';
      selectedRole = 'Cashier';
      dashboard.clear();
      users.clear();
      products.clear();
      categories.clear();
      suppliers.clear();
      purchaseOrders.clear();
      discountApprovals.clear();
      invoices.clear();
      whatsappMessages.clear();
      auditLogs.clear();
      rolePermissions.clear();
      storeSettings.clear();
      settingsDraft.clear();
      permissions.updateAll((key, value) => false);
      staffActive.clear();
      categoryActive.clear();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
