import 'package:flutter/foundation.dart';

import 'user_api.dart';
import 'user_models.dart';

class UserState extends ChangeNotifier {
  UserState({UserApi? api}) : api = api ?? UserApi();
  final UserApi api;
  UserPage page = UserPage.login;
  UserPage? previousPage;
  bool loading = true;
  String? error;
  Map<String, dynamic> user = {}, dashboard = {}, lastInvoice = {}, paymentSummary = {};
  List<Map<String, dynamic>> categories = [], products = [], batches = [], reviews = [], invoices = [];
  final List<CartLine> cart = [];
  int navIndex = 0;
  String search = '', stockFilter = 'All', reviewFilter = 'All', expiryFilter = '30 Days';
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

  Future<void> refresh() async {
    await _perform(() async {
      switch (page) {
        case UserPage.dashboard:
          dashboard = await api.getMap('dashboard');
          break;
        case UserPage.inventory || UserPage.addProduct:
          categories = await api.getList('categories');
          break;
        case UserPage.currentStock || UserPage.shelfAging || UserPage.billing:
          products = await api.getList(
            page == UserPage.shelfAging ? 'inventory/shelf-stock' : 'inventory/current-stock',
            query: page != UserPage.currentStock || selectedCategoryId == null
                ? null
                : {'category': '$selectedCategoryId'},
          );
          break;
        case UserPage.expiry:
          batches = await api.getList('inventory/expiry');
          break;
        case UserPage.quantityReview:
          reviews = await api.getList('inventory/quantity-reviews');
          break;
        case UserPage.reports:
          paymentSummary = await api.getMap('payments/summary', query: {'range': 'today'});
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
      UserPage.inventory || UserPage.addProduct || UserPage.currentStock || UserPage.shelfAging || UserPage.quantityReview || UserPage.expiry => 1,
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
      });

  Future<bool> moveToShelf(int itemId, int quantity) async =>
      _perform(() async {
        await api.post('items/$itemId/move-to-shelf', {'quantity': quantity});
        products = await api.getList('inventory/shelf-stock');
      });

  Future<bool> updateBatchStatus(int batchId, String action) async =>
      _perform(() async {
        await api.post('inventory/batches/$batchId/$action', const {});
        batches = await api.getList('inventory/expiry');
      });

  bool get canManageInventory =>
      {'inventory', 'manager'}.contains(user['role']?.toString().toLowerCase());

  Future<bool> createProduct(Map<String, dynamic> values) async =>
      _perform(() async {
        await api.post('products', values);
        products = await api.getList('inventory/current-stock');
        categories = await api.getList('categories');
        page = UserPage.currentStock;
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
    on UserApiException catch (e) { error = e.message; return false; }
    catch (_) { error = 'Something went wrong. Please retry.'; return false; }
    finally { loading = false; notifyListeners(); }
  }
}
