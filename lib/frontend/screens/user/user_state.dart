import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'user_api.dart';
import 'user_models.dart';

class BulkShelfActionResult {
  const BulkShelfActionResult(this.completed, this.failed);
  final int completed;
  final int failed;
  bool get isComplete => failed == 0;
}

class UserState extends ChangeNotifier {
  UserState({UserApi? api}) : api = api ?? UserApi();
  final UserApi api;
  UserPage page = UserPage.login;
  UserPage? previousPage;
  bool loading = true;
  String? error;
  Map<String, dynamic> user = {}, dashboard = {}, lastInvoice = {}, paymentSummary = {};
  List<Map<String, dynamic>> categories = [], products = [], batches = [], reviews = [], invoices = [], stockMovements = [];
  final List<CartLine> cart = [];
  int navIndex = 0;
  String search = '', stockFilter = 'All', reviewFilter = 'All', expiryFilter = '30 Days';
  String movementPeriod = 'Today';
  DateTime? movementStartDate, movementEndDate;
  int? selectedCategoryId;
  String selectedCategoryName = '';

  Future<void> initialize() async {
    user = await api.restore();
    loading = false;
    if (user.isNotEmpty) page = UserPage.dashboard;
    notifyListeners();
    if (user.isNotEmpty) await refresh();
  }

  Future<bool> login(String id, String password) async => _perform(() async {
    user = await api.login(id, password);
    final role = user['role']?.toString().toLowerCase();
    if (role == 'admin' || role == 'manager') {
      await api.clearSession();
      user = {};
      throw const UserApiException(
        'Admin accounts must sign in through the Admin workspace.',
      );
    }
    page = UserPage.verification;
  });

  Future<bool> changePassword({
    required String identifier,
    required String currentPassword,
    required String newPassword,
  }) async => _perform(() async {
    await api.changePassword(
      identifier: identifier,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  });

  Future<void> refresh() async {
    await _perform(() async {
      switch (page) {
        case UserPage.dashboard:
          dashboard = await api.getMap('dashboard');
          break;
        case UserPage.inventory || UserPage.addProduct:
          categories = await api.getList('categories');
          break;
        case UserPage.currentStock:
          products = await api.getStoreStock(
            query: selectedCategoryId == null
                ? null
                : {'category': '$selectedCategoryId'},
          );
          break;
        case UserPage.shelfAging:
          products = await api.getShelfStock();
          break;
        case UserPage.stockMovement:
          stockMovements = await api.getList('inventory/stock-movements', query: _movementDateQuery());
          break;
        case UserPage.billing:
          products = await api.getList('inventory/current-stock');
          break;
        case UserPage.expiry:
          batches = await api.getList('inventory/expiry');
          break;
        case UserPage.quantityReview:
          final results = await Future.wait([
            api.getList('inventory/quantity-reviews'),
            api.getShelfStock(),
          ]);
          reviews = results[0];
          products = results[1];
          break;
        case UserPage.reports:
          final results = await Future.wait([
            api.getMap('payments/summary', query: {'range': 'today'}),
            api.getList('invoices'),
          ]);
          paymentSummary = results[0] as Map<String, dynamic>;
          invoices = results[1] as List<Map<String, dynamic>>;
          break;
        case UserPage.invoice || UserPage.profile:
          invoices = await api.getList('invoices');
          break;
        default:
          break;
      }
    }, showLoader: true);
  }

  void go(UserPage value, {bool load = true, bool remember = true}) {
    if (remember && value != page) previousPage = page;
    page = value;
    navIndex = switch (value) {
      UserPage.dashboard => 0,
      UserPage.inventory || UserPage.addProduct || UserPage.currentStock || UserPage.shelfAging || UserPage.stockMovement || UserPage.quantityReview || UserPage.expiry => 1,
      UserPage.billing || UserPage.payment || UserPage.invoice => 2,
      UserPage.reports => 3,
      UserPage.profile => 4,
      _ => navIndex,
    };
    error = null;
    notifyListeners();
    if (load) refresh();
  }

  void back({UserPage fallback = UserPage.dashboard}) {
    final destination = previousPage ?? fallback;
    previousPage = null;
    go(destination, remember: false);
  }

  void setNav(int index) {
    if (index == 1 || index == 2) clearSelectedCategory();
    go([UserPage.dashboard, UserPage.inventory, UserPage.billing, UserPage.reports, UserPage.profile][index], remember: false);
  }
  void openCategory(Map<String, dynamic> category) {
    selectedCategoryId = int.tryParse('${category['id']}');
    selectedCategoryName = '${category['name']}';
    search = '';
    stockFilter = 'All';
    go(UserPage.currentStock);
  }
  void clearSelectedCategory() {
    selectedCategoryId = null;
    selectedCategoryName = '';
  }
  void setSearch(String value) { search = value; notifyListeners(); }
  void setStockFilter(String value) { stockFilter = value; notifyListeners(); }
  void setReviewFilter(String value) { reviewFilter = value; notifyListeners(); }
  void setExpiryFilter(String value) { expiryFilter = value; notifyListeners(); }
  void setMovementPeriod(String value) {
    movementPeriod = value;
    if (value != 'Custom') {
      movementStartDate = null;
      movementEndDate = null;
    }
    refresh();
    notifyListeners();
  }
  void setMovementDateRange(DateTime start, DateTime end) {
    movementPeriod = 'Custom';
    movementStartDate = start;
    movementEndDate = end;
    refresh();
    notifyListeners();
  }

  Map<String, String> _movementDateQuery() {
    final today = DateTime.now();
    DateTime start = today, end = today;
    switch (movementPeriod) {
      case 'Week': start = today.subtract(const Duration(days: 6)); break;
      case 'Month': start = DateTime(today.year, today.month); break;
      case 'Year': start = DateTime(today.year); break;
      case 'Custom':
        if (movementStartDate == null || movementEndDate == null) return {};
        start = movementStartDate!;
        end = movementEndDate!;
        break;
    }
    String format(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return {'start_date': format(start), 'end_date': format(end)};
  }

  List<Map<String, dynamic>> get visibleProducts => products.where((p) {
    final q = search.toLowerCase();
    final matches = q.isEmpty || '${p['name']} ${p['sku']} ${p['barcode']}'.toLowerCase().contains(q);
    final status = p['stock_status']?.toString() ?? '';
    final statusMatch = stockFilter == 'All' || status.replaceAll('_', ' ').toLowerCase() == stockFilter.toLowerCase();
    return matches && statusMatch;
  }).toList();

  void addProduct(Map<String, dynamic> product) {
    final available = int.tryParse('${product['stock_quantity'] ?? product['total_stock'] ?? 0}') ?? 0;
    final existing = cart.where((line) => line.id == product['id']);
    if (available <= 0) { error = '${product['name']} is out of stock.'; notifyListeners(); return; }
    if (existing.isEmpty) cart.add(CartLine(product: product));
    else if (existing.first.quantity < available) existing.first.quantity++;
    else error = 'Only $available units are available.';
    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta) {
    final next = line.quantity + delta;
    if (next <= 0) cart.remove(line);
    else if (next <= line.available) line.quantity = next;
    else error = 'Only ${line.available} units are available.';
    notifyListeners();
  }

  double get subtotal => cart.fold(0, (sum, line) => sum + line.total);
  double get gst => cart.fold(0, (sum, line) => sum + line.total * (double.tryParse('${line.product['tax_percent'] ?? 0}') ?? 0) / 100);
  double get grandTotal => subtotal + gst;

  Future<bool> checkout(List<Map<String, dynamic>> payments) async => _perform(() async {
    lastInvoice = await api.post('billing/checkout', {
      'items': cart.map((line) => {'item': line.id, 'quantity': line.quantity}).toList(),
      'payments': payments,
    });
    invoices = await api.getList('invoices');
    cart.clear();
    page = UserPage.invoice;
  });

  Future<bool> reviewQuantity(int itemId, int physicalQuantity, {String reason = 'Staff physical stock review'}) async =>
      _perform(() async {
        await api.post('inventory/quantity-reviews', {
          'item': itemId,
          'physical_quantity': physicalQuantity,
          'reason': reason,
        });
        reviews = await api.getList('inventory/quantity-reviews');
        products = await api.getShelfStock();
      });

  Future<bool> moveToShelf(int itemId, int quantity) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.post('inventory/move-to-shelf', {'product_id': itemId, 'quantity': quantity});
      try {
        products = await api.getStoreStock();
      } catch (_) {
        // The transfer already committed; a refresh failure must not report
        // the completed transaction as unsuccessful.
      }
      return true;
    } on UserApiException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> shelfProductAction(int productId, String action, Map<String, dynamic> values) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await api.post('inventory/shelf-stock/$productId/$action', values);
      products = await api.getShelfStock();
      return true;
    } on UserApiException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<BulkShelfActionResult> bulkShelfProductAction(List<int> productIds, String action, Map<String, dynamic> values) async {
    loading = true;
    error = null;
    notifyListeners();
    var completed = 0;
    var failed = 0;
    try {
      for (final productId in productIds) {
        try {
          await api.post('inventory/shelf-stock/$productId/$action', values);
          completed++;
        } on UserApiException {
          failed++;
        }
      }
      products = await api.getShelfStock();
      if (failed > 0) error = '$failed selected product${failed == 1 ? '' : 's'} could not be updated.';
      return BulkShelfActionResult(completed, failed);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBatchStatus(int batchId, String action) async =>
      _perform(() async {
        await api.post('inventory/batches/$batchId/$action', const {});
        batches = await api.getList('inventory/expiry');
      });

  bool get canManageInventory =>
      {'inventory', 'manager', 'cashier'}.contains(user['role']?.toString().toLowerCase());

  Future<bool> createProduct(Map<String, dynamic> values, {XFile? image}) async =>
      _perform(() async {
        if (image == null) {
          await api.post('products', values);
        } else {
          await api.uploadProduct(values, image: image);
        }
        products = await api.getStoreStock();
        categories = await api.getList('categories');
        page = UserPage.currentStock;
      });

  Future<bool> deleteProduct(int productId) async => _perform(() async {
        await api.delete('products/$productId');
        products.removeWhere((product) => '${product['product_id'] ?? product['id']}' == '$productId');
      });

  Future<bool> scheduleProductPrice(int productId, Map<String, dynamic> fields) async =>
      _perform(() async {
        await api.post('products/$productId/price-schedule', fields);
        products = await api.getStoreStock();
      });

  Future<void> logout() async {
    await api.logout();
    user = {}; dashboard = {}; cart.clear(); page = UserPage.login; navIndex = 0; error = null;
    notifyListeners();
  }

  Future<bool> _perform(Future<void> Function() action, {bool showLoader = true}) async {
    if (showLoader) loading = true;
    error = null;
    notifyListeners();
    try { await action(); return true; }
    on UserApiException catch (e) {
      error = e.message;
      if (e.message.contains('session has expired')) page = UserPage.login;
      return false;
    }
    catch (_) { error = 'Something went wrong. Please retry.'; return false; }
    finally { loading = false; notifyListeners(); }
  }
}
