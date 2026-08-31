import 'dart:async';

import 'package:flutter/foundation.dart';

import 'admin_api.dart';

class AdminState extends ChangeNotifier {
  AdminState({AdminApi? api, this.onLoggedOut}) : api = api ?? AdminApi();

  final VoidCallback? onLoggedOut;

  bool _disposed = false;
  Timer? _paymentNotificationPoller;
  final List<int> _navigationHistory = [];

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

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
  bool wakingServer = false;
  int wakeAttempt = 0;
  int wakeMaxAttempts = 0;
  bool refreshing = false;
  bool decidingPurchaseOrder = false;
  bool decidingDiscount = false;
  bool savingPermissions = false;
  bool permissionsDirty = false;
  String? error;
  String passwordChangeIdentifier = '';
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> racks = [];
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> suppliers = [];
  List<Map<String, dynamic>> purchaseOrders = [];
  List<Map<String, dynamic>> discountApprovals = [];
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> productBatches = [];
  List<Map<String, dynamic>> stockReviews = [];
  List<Map<String, dynamic>> stockAdjustments = [];
  List<Map<String, dynamic>> whatsappMessages = [];
  List<Map<String, dynamic>> auditLogs = [];
  List<Map<String, dynamic>> rolePermissions = [];
  Map<String, dynamic> storeSettings = {};
  Map<String, dynamic> settingsDraft = {};
  Map<String, dynamic> selectedUserDetails = {};
  int?
  pendingCategoryId; // pre-selects a category when navigating to Add Product

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

  bool get canGoBack => _navigationHistory.isNotEmpty;

  void go(int value) {
    var destination = value.clamp(0, 20);
    if (!loggedIn && destination != 0 && destination != 16) {
      destination = 0;
    }
    if (loggedIn && destination != screen) {
      _navigationHistory.add(screen);
    }
    _applyDestination(destination);
    notifyListeners();
  }

  void goBack({int? fallback}) {
    int? destination;
    while (_navigationHistory.isNotEmpty && destination == null) {
      final candidate = _navigationHistory.removeLast();
      if (candidate != screen) destination = candidate;
    }
    destination ??= fallback ?? (loggedIn ? 1 : 0);
    _applyDestination(destination);
    notifyListeners();
  }

  void _applyDestination(int destination) {
    screen = destination;
    // Page-level request errors should not follow the user into an unrelated
    // workspace. A fresh request on the destination can report its own error.
    error = null;
    navIndex = switch (destination) {
      1 => 0,
      2 || 3 || 18 => 1,
      >= 10 && <= 13 => 2,
      17 => 3,
      14 || 15 || 16 => 4,
      _ => navIndex,
    };
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
    wakingServer = true;
    wakeAttempt = 0;
    wakeMaxAttempts = 4;
    error = null;
    notifyListeners();
    try {
      final serverReady = await api.waitForServer(
        maxAttempts: wakeMaxAttempts,
        initialDelay: const Duration(seconds: 1),
        onAttempt: (attempt, max) {
          wakeAttempt = attempt;
          wakeMaxAttempts = max;
          notifyListeners();
        },
      );
      if (!serverReady) {
        error =
            'Server is taking longer than expected to wake up. Please retry.';
        return false;
      }
      wakingServer = false;
      notifyListeners();
      final session = await api.login(email, password);
      final user = (session['user'] as Map?)?.cast<String, dynamic>() ?? {};
      final role = user['role']?.toString();
      if (!{'admin', 'manager'}.contains(role)) {
        api.clearSession();
        error = 'Only Admin or Store Manager accounts can open this workspace.';
        return false;
      }
      loggedIn = true;
      _navigationHistory.clear();
      passwordChangeIdentifier = email;
      screen = 1;
      _startPaymentNotificationPolling();
      notifyListeners();
      unawaited(reloadAll());
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
      return false;
    } finally {
      wakingServer = false;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    Object? firstFailure;
    var loaded = 0;
    Future<T?> load<T>(Future<T> Function() request) async {
      try {
        final value = await request();
        loaded++;
        return value;
      } catch (exception) {
        firstFailure ??= exception;
        return null;
      }
    }

    // Load sequentially. A Render free-tier instance can abort connections
    // when the phone opens all dashboard requests at the same time. Products
    // come first because the catalogue is the most commonly opened screen.
    final newProducts = await load(_loadProductsWithStoreStock);
    if (newProducts != null) products = newProducts;
    final newCategories = await load(() => api.getList('categories'));
    if (newCategories != null) categories = newCategories;
    final newBrands = await load(() => api.getList('brands'));
    if (newBrands != null) brands = newBrands;
    final newDashboard = await load(() => api.getMap('dashboard'));
    if (newDashboard != null) dashboard = newDashboard;
    final newUsers = await load(() => api.getList('users'));
    if (newUsers != null) users = newUsers;
    final newSuppliers = await load(() => api.getList('suppliers'));
    if (newSuppliers != null) suppliers = newSuppliers;
    final newPurchaseOrders = await load(() => api.getList('purchase-orders'));
    if (newPurchaseOrders != null) purchaseOrders = newPurchaseOrders;
    final newDiscounts = await load(() => api.getList('discount-approvals'));
    if (newDiscounts != null) discountApprovals = newDiscounts;
    final newInvoices = await load(() => api.getList('invoices'));
    if (newInvoices != null) invoices = newInvoices;
    final newPayments = await load(() => api.getList('payments'));
    if (newPayments != null) payments = newPayments;
    final newBatches = await load(() => api.getList('inventory/batches'));
    if (newBatches != null) productBatches = newBatches;
    final newReviews = await load(
      () => api.getList('inventory/quantity-reviews'),
    );
    if (newReviews != null) stockReviews = newReviews;
    final newAdjustments = await load(
      () => api.getList('inventory/stock-adjustments'),
    );
    if (newAdjustments != null) stockAdjustments = newAdjustments;
    final newAuditLogs = await load(() => api.getList('audit-logs'));
    if (newAuditLogs != null) auditLogs = newAuditLogs;
    final newPermissions = await load(() => api.getList('role-permissions'));
    if (newPermissions != null) rolePermissions = newPermissions;
    final settings = await load(() => api.getList('store-settings'));
    if (settings != null) {
      storeSettings = settings.isEmpty ? {} : settings.first;
    }
    final newMessages = await load(() => api.getList('whatsapp-messages'));
    if (newMessages != null) whatsappMessages = newMessages;
    if (loaded == 0 && firstFailure != null) throw firstFailure!;
    settingsDraft = Map<String, dynamic>.from(storeSettings);
    if (rolePermissions.isNotEmpty) {
      selectedRole = _roleLabel(rolePermissions.first['role'].toString());
    }
    _hydrateControls();
    notifyListeners();
  }

  List<Map<String, dynamic>> get paymentNotifications => auditLogs
      .where(
        (entry) =>
            entry['module']?.toString() == 'Payments' &&
            entry['action']?.toString() == 'Payment Received',
      )
      .toList();

  void _startPaymentNotificationPolling() {
    _paymentNotificationPoller?.cancel();
    _paymentNotificationPoller = Timer.periodic(const Duration(seconds: 30), (
      _,
    ) async {
      if (!loggedIn || _disposed) return;
      try {
        auditLogs = await api.getList('audit-logs');
        notifyListeners();
      } catch (_) {
        // A temporary network failure must not interrupt the admin workspace.
      }
    });
  }

  Future<bool> refreshCategories() async {
    try {
      categories = await api.getList('categories');
      _hydrateControls();
      error = null;
      notifyListeners();
      return true;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshRacks() async {
    try {
      racks = await api.getList('racks', query: const {'active': 'true'});
      error = null;
      notifyListeners();
      return true;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshProducts() async {
    try {
      products = await _loadProductsWithStoreStock();
      productQuery = '';
      error = null;
      notifyListeners();
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Cannot reach ${api.baseUrl}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshAuditLogs() async {
    if (refreshing) return false;
    refreshing = true;
    error = null;
    notifyListeners();
    try {
      auditLogs = await api.getList('audit-logs');
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

  /// The catalogue owns product details; StoreStock owns the live quantity at
  /// the current branch. Keep both in one card model for Product Management.
  Future<List<Map<String, dynamic>>> _loadProductsWithStoreStock() async {
    final catalogue = await api.getList('items');
    try {
      final storeRows = await api.getList('inventory/store-stock');
      final byProductId = <String, Map<String, dynamic>>{
        for (final row in storeRows) '${row['product_id']}': row,
      };
      return catalogue.map((product) {
        final stock = byProductId['${product['id']}'];
        if (stock == null) return product;
        return {
          ...product,
          'store_stock': stock['store_quantity'] ?? 0,
          'minimum_quantity':
              stock['minimum_quantity'] ?? product['reorder_level'] ?? 0,
          'store_stock_updated_at': stock['updated_at'],
        };
      }).toList();
    } on ApiException {
      // The catalogue remains usable if a server is temporarily upgrading the
      // split-stock endpoint. A later refresh will show the live store values.
      return catalogue;
    }
  }

  Future<bool> reloadAll() async {
    if (refreshing) return false;
    refreshing = true;
    error = null;
    notifyListeners();
    try {
      // Do one lightweight connectivity gate before the many workspace reads.
      // Without this, an unavailable Render instance makes every sequential
      // endpoint exhaust its own retries and the UI can appear stuck for
      // several minutes. Existing cached data remains usable while offline.
      final serverReady = await api.waitForServer(
        maxAttempts: 2,
        initialDelay: const Duration(seconds: 1),
      );
      if (!serverReady) {
        error =
            'Server is waking up or temporarily unavailable. '
            'Showing your previously loaded data.';
        return false;
      }
      await refreshAll();
      error = null;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error =
          'Connection interrupted while syncing. '
          'Showing your previously loaded data.';
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
    _hydrateSelectedRolePermissions();
  }

  String get _selectedRoleKey => switch (selectedRole) {
    'Store Manager' => 'manager',
    _ => selectedRole.toLowerCase().replaceAll(' ', '_'),
  };

  void _hydrateSelectedRolePermissions() {
    permissions.updateAll((key, value) => false);
    final selected = rolePermissions.where(
      (row) => row['role'] == _selectedRoleKey,
    );
    if (selected.isNotEmpty) {
      for (final key in permissions.keys) {
        permissions[key] = selected.first[key.toLowerCase()] == true;
      }
    }
  }

  List<String> get availableRoles {
    const supported = [
      'Admin',
      'Store Manager',
      'Cashier',
      'Sales',
      'Accountant',
      'Inventory',
    ];
    final loaded = rolePermissions
        .map((row) => _roleLabel(row['role'].toString()))
        .where((role) => role.isNotEmpty);
    return {...supported, ...loaded}.toList();
  }

  String _roleLabel(String value) {
    if (value == 'manager') return 'Store Manager';
    return value
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void setNav(int index) {
    final destination = switch (index) {
      0 => 1,
      1 => 2,
      2 => 10,
      3 => 17,
      _ => 14,
    };
    go(destination);
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
    permissionsDirty = true;
    notifyListeners();
  }

  void setAllPermissions(bool value) {
    permissions.updateAll((key, previous) => value);
    permissionsDirty = true;
    notifyListeners();
  }

  void applyPermissionPreset() {
    final enabled = switch (_selectedRoleKey) {
      'admin' || 'manager' => permissions.keys.toSet(),
      'cashier' => {'Dashboard', 'Billing', 'Returns'},
      'inventory' => {'Dashboard', 'Products', 'Inventory', 'Reports'},
      'accountant' => {'Dashboard', 'Billing', 'Reports', 'Returns'},
      _ => {'Dashboard', 'Products', 'Billing'},
    };
    for (final key in permissions.keys) {
      permissions[key] = enabled.contains(key);
    }
    permissionsDirty = true;
    notifyListeners();
  }

  void setRole(String value) {
    selectedRole = value;
    _hydrateSelectedRolePermissions();
    permissionsDirty = false;
    notifyListeners();
  }

  Future<void> savePermissions() async {
    if (savingPermissions) return;
    savingPermissions = true;
    error = null;
    notifyListeners();
    try {
      final role = _selectedRoleKey;
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
      permissionsDirty = false;
      _hydrateSelectedRolePermissions();
    } finally {
      savingPermissions = false;
      notifyListeners();
    }
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

  Future<void> decideDiscount(bool approved, {String reviewNote = ''}) async {
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
      await api
          .action('discount-approvals', pending.first['id'] as int, 'decide', {
            'decision': approved ? 'approved' : 'rejected',
            'review_note': reviewNote.trim(),
          });
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
    Map<String, dynamic> values, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final created = imageBytes == null || imageName == null
        ? await api.create('items', values)
        : await api.createWithImage(
            'items',
            values,
            imageBytes: imageBytes,
            imageName: imageName,
          );
    products = [
      created,
      ...products.where((product) => product['id'] != created['id']),
    ];
    productQuery = '';
    notifyListeners();
    // Product creation is complete at this point. Dashboard aggregation is a
    // secondary read and must never keep the Add Product button in "Saving".
    unawaited(_refreshDashboardAfterProductCreate());
    return created;
  }

  Future<void> _refreshDashboardAfterProductCreate() async {
    try {
      dashboard = await api.getMap('dashboard');
    } catch (_) {
      // The product is already saved; dashboard can refresh on the next visit.
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> createBrand(Map<String, dynamic> values) async {
    final created = await api.create('brands', values);
    brands = [created, ...brands.where((brand) => brand['id'] != created['id'])]
      ..sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    notifyListeners();
    return created;
  }

  Future<void> toggleBrand(Map<String, dynamic> brand, bool value) async {
    final previous = brand['is_active'] == true;
    brand['is_active'] = value;
    notifyListeners();
    try {
      final updated = await api.update('brands', brand['id'] as int, {
        'is_active': value,
      });
      brand.addAll(updated);
    } catch (error) {
      brand['is_active'] = previous;
      notifyListeners();
      rethrow;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String customerMobile = '',
    double discountPercent = 0,
  }) async {
    final subtotal = items.fold<double>(0, (sum, line) {
      final product = line['product'] as Map<String, dynamic>;
      final price = double.tryParse(product['selling_price'].toString()) ?? 0;
      final tax = double.tryParse(product['tax_percent'].toString()) ?? 0;
      final quantity = line['quantity'] as int;
      return sum + (price * quantity * (1 + tax / 100));
    });
    final payable = subtotal * (1 - discountPercent / 100);
    final invoice = await api.create('billing/checkout', {
      'items': [
        for (final line in items)
          {
            'product': (line['product'] as Map<String, dynamic>)['id'],
            'quantity': line['quantity'],
          },
      ],
      'discount_percent': discountPercent.toStringAsFixed(2),
      'customer_mobile': customerMobile.trim(),
      'payments': [
        {'method': paymentMethod, 'amount': payable.toStringAsFixed(2)},
      ],
    });
    products = await api.getList('items');
    invoices = await api.getList('invoices');
    payments = await api.getList('payments');
    dashboard = await api.getMap('dashboard');
    notifyListeners();
    return invoice;
  }

  Future<void> updateProductImage(
    int productId,
    Uint8List imageBytes,
    String imageName,
  ) async {
    final updated = await api.updateWithImage(
      'items',
      productId,
      imageBytes: imageBytes,
      imageName: imageName,
    );
    products = products
        .map((product) => product['id'] == productId ? updated : product)
        .toList();
    notifyListeners();
  }

  /// Patches price / GST / MRP fields on a product and refreshes
  /// quotations so open bills always reflect the latest price.
  Future<void> updateProduct(int productId, Map<String, dynamic> fields) async {
    final updated = await api.update('items', productId, fields);
    products = products.map((p) => p['id'] == productId ? updated : p).toList();
    // Reload quotations because the backend may have recalculated open ones.
    try {
      purchaseOrders = await api.getList('purchase-orders');
      dashboard = await api.getMap('dashboard');
    } on ApiException {
      // Non-fatal — the product update already succeeded.
    }
    notifyListeners();
  }

  /// Schedule purchase price, selling price and GST for a specific date.
  /// The backend keeps existing invoices unchanged and uses this rate on/after
  /// its effective date.
  Future<void> scheduleProductPrice(
    int productId,
    Map<String, dynamic> fields,
  ) async {
    await api.action('items', productId, 'price-schedule', fields);
    products = await api.getList('items');
    notifyListeners();
  }

  Future<void> deleteProduct(int productId) async {
    await api.delete('items', productId);
    products.removeWhere((product) => product['id'] == productId);
    notifyListeners();
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
    var recoverCreate = false;
    try {
      await api.create('categories', {'name': name.trim(), 'is_active': true});
    } on ApiException catch (exception) {
      if (!exception.message.toLowerCase().contains('already exists')) {
        rethrow;
      }
    } catch (_) {
      // A mobile connection can be aborted after Render has accepted the
      // request. Wake the service and read the collection before reporting a
      // failure; this also avoids blindly repeating a POST.
      final alive = await api.waitForServer(maxAttempts: 3);
      if (!alive) {
        throw ApiException(
          'Cannot reach ${api.baseUrl}. Check your internet connection.',
        );
      }
      recoverCreate = true;
    }
    if (recoverCreate) {
      categories = await api.getList('categories');
      final savedDuringDisconnect = categories.where(
        (category) =>
            category['name']?.toString().trim().toLowerCase() == normalized,
      );
      if (savedDuringDisconnect.isNotEmpty) {
        _hydrateControls();
        notifyListeners();
        return savedDuringDisconnect.first;
      }
      try {
        await api.create('categories', {
          'name': name.trim(),
          'is_active': true,
        });
      } on ApiException catch (exception) {
        if (!exception.message.toLowerCase().contains('already exists')) {
          rethrow;
        }
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

  Future<void> openUserDetails(int userId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      selectedUserDetails = await api.getMap('users/$userId/summary');
      go(18);
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Unable to load user details.';
    } finally {
      loading = false;
      notifyListeners();
    }
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

  Future<void> resendInvoice(
    Map<String, dynamic>? selectedInvoice, {
    String? recipientOverride,
    String? message,
  }) async {
    if (invoices.isEmpty) {
      throw const ApiException('No invoice is available to send.');
    }
    final invoice = selectedInvoice ?? invoices.first;
    final recipient =
        (recipientOverride?.trim().isNotEmpty == true
                ? recipientOverride
                : invoice['client_mobile']?.toString())
            ?.trim() ??
        '';
    if (recipient.isEmpty) {
      throw const ApiException(
        'The selected invoice has no customer mobile number.',
      );
    }
    await api.create('whatsapp-messages', {
      'invoice': invoice['id'],
      'recipient': recipient,
      'message': message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Your invoice ${invoice['number']} is ready.',
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

  Future<void> logout({String? reason, String? suggestion}) async {
    if (loggingOut) return;
    loggingOut = true;
    error = null;
    notifyListeners();
    try {
      await api.logout(reason: reason, suggestion: suggestion);
    } catch (_) {
      // Local logout must still complete if the server is temporarily offline.
    } finally {
      api.clearSession();
      _paymentNotificationPoller?.cancel();
      _paymentNotificationPoller = null;
      loggedIn = false;
      _navigationHistory.clear();
      screen = 0;
      navIndex = 0;
      logoutConfirmationVisible = false;
      loggingOut = false;
      refreshing = false;
      decidingPurchaseOrder = false;
      decidingDiscount = false;
      savingPermissions = false;
      permissionsDirty = false;
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
      racks.clear();
      suppliers.clear();
      purchaseOrders.clear();
      discountApprovals.clear();
      invoices.clear();
      payments.clear();
      productBatches.clear();
      stockReviews.clear();
      stockAdjustments.clear();
      whatsappMessages.clear();
      auditLogs.clear();
      rolePermissions.clear();
      storeSettings.clear();
      settingsDraft.clear();
      selectedUserDetails.clear();
      permissions.updateAll((key, value) => false);
      staffActive.clear();
      categoryActive.clear();
      notifyListeners();
      onLoggedOut?.call();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _paymentNotificationPoller?.cancel();
    api.dispose();
    super.dispose();
  }
}
