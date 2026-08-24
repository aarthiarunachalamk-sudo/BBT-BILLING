class CartLine {
  CartLine({required this.product, this.quantity = 1});
  final Map<String, dynamic> product;
  int quantity;
  int get id => product['id'] as int;
  String get name => product['name']?.toString() ?? 'Product';
  double get price => double.tryParse('${product['selling_price'] ?? 0}') ?? 0;
  int get available => int.tryParse('${product['stock_quantity'] ?? product['total_stock'] ?? 0}') ?? 0;
  double get total => price * quantity;
}

enum UserPage {
  login,
  verification,
  dashboard,
  inventory,
  addProduct,
  currentStock,
  shelfAging,
  stockMovement,
  quantityReview,
  expiry,
  billing,
  payment,
  reports,
  invoice,
  profile,
}
