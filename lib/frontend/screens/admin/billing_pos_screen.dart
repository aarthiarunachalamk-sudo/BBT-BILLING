part of 'admin_screens.dart';

class _EditBillingPriceDialog extends StatefulWidget {
  const _EditBillingPriceDialog({
    required this.state,
    required this.product,
    required this.initialPrice,
  });

  final AdminState state;
  final Map<String, dynamic> product;
  final double initialPrice;

  @override
  State<_EditBillingPriceDialog> createState() =>
      _EditBillingPriceDialogState();
}

class _EditBillingPriceDialogState extends State<_EditBillingPriceDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController controller;
  bool saving = false;
  String? errorText;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initialPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: .09),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.currency_rupee_rounded, color: blue),
    ),
    title: const Text('Update selling price'),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product['name']?.toString() ?? 'Product',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('billing-price-field'),
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Selling price',
                prefixText: '₹ ',
              ),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                if (price == null || price <= 0) {
                  return 'Enter a valid price greater than zero';
                }
                return null;
              },
            ),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                style: const TextStyle(color: red, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: saving ? null : _save,
        icon: saving
            ? const SizedBox.square(
                dimension: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded),
        label: Text(saving ? 'Saving...' : 'Save price'),
      ),
    ],
  );

  Future<void> _save() async {
    if (formKey.currentState?.validate() != true) return;
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      await widget.state.updateProduct(widget.product['id'] as int, {
        'selling_price': controller.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        saving = false;
        errorText = error.toString();
      });
    }
  }
}

class BillingPosScreen extends StatefulWidget {
  const BillingPosScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<BillingPosScreen> createState() => _BillingPosScreenState();
}

class _BillingPosScreenState extends State<BillingPosScreen> {
  final search = TextEditingController();
  final mobile = TextEditingController();
  final Map<int, int> cart = {};
  String paymentMethod = 'upi';
  bool submitting = false;

  @override
  void dispose() {
    search.dispose();
    mobile.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get products {
    final query = search.text.trim().toLowerCase();
    return widget.state.products.where((product) {
      if (product['is_active'] != true) return false;
      if (query.isEmpty) return true;
      return ['name', 'sku', 'barcode'].any(
        (key) => product[key]?.toString().toLowerCase().contains(query) == true,
      );
    }).toList();
  }

  Map<String, dynamic> _product(int id) =>
      widget.state.products.firstWhere((product) => product['id'] == id);

  double _price(Map<String, dynamic> product) =>
      double.tryParse(product['selling_price']?.toString() ?? '') ?? 0;
  double _tax(Map<String, dynamic> product) =>
      double.tryParse(product['tax_percent']?.toString() ?? '') ?? 0;
  double get subtotal => cart.entries.fold(
    0,
    (sum, entry) => sum + _price(_product(entry.key)) * entry.value,
  );
  double get gst => cart.entries.fold(0, (sum, entry) {
    final product = _product(entry.key);
    return sum + _price(product) * entry.value * _tax(product) / 100;
  });

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'New Bill',
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Scan barcode / search product or SKU',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Scan barcode',
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ),
          ),
        ),
        Expanded(child: cart.isEmpty ? _catalog() : _cart()),
        if (cart.isNotEmpty) _checkoutBar(context),
      ],
    ),
  );

  Widget _catalog() {
    final visibleProducts = products;
    if (visibleProducts.isEmpty) {
      return const _EmptyState(
        'No products found.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
      itemCount: visibleProducts.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: blue.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: blue,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${visibleProducts.length} products available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                      const Text(
                        'Tap price to add  •  Use menu to manage',
                        style: TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return _catalogProductCard(visibleProducts[index - 1]);
      },
    );
  }

  Widget _catalogProductCard(Map<String, dynamic> product) {
    final stock = int.tryParse(product['stock_quantity'].toString()) ?? 0;
    final image = product['image']?.toString() ?? '';
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 9, 12),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: line),
            ),
            child: image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.inventory_2_outlined, color: muted),
                    ),
                  )
                : const Icon(Icons.inventory_2_outlined, color: muted),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product['sku'] ?? 'No SKU'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, color: muted),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: stock > 0
                        ? green.withValues(alpha: .09)
                        : red.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stock > 0 ? '$stock in stock' : 'Out of stock',
                    style: TextStyle(
                      color: stock > 0 ? green : red,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _productActionButton(
                    key: ValueKey('billing-sticker-product-${product['id']}'),
                    tooltip: 'Generate product sticker',
                    icon: Icons.qr_code_2_rounded,
                    foreground: blue,
                    background: blue.withValues(alpha: .10),
                    onPressed: () => _showProductStickerSheet(context, product),
                  ),
                  const SizedBox(width: 6),
                  _productActionButton(
                    key: ValueKey('billing-edit-product-${product['id']}'),
                    tooltip: 'Edit price',
                    icon: Icons.edit_rounded,
                    foreground: violet,
                    background: violet.withValues(alpha: .10),
                    onPressed: () => _editProductPrice(product),
                  ),
                  const SizedBox(width: 6),
                  _productActionButton(
                    key: ValueKey('billing-delete-product-${product['id']}'),
                    tooltip: 'Delete product',
                    icon: Icons.delete_outline_rounded,
                    foreground: red,
                    background: red.withValues(alpha: .09),
                    onPressed: () => _deleteProduct(product),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              FilledButton.icon(
                key: ValueKey('billing-add-product-${product['id']}'),
                onPressed: stock <= 0
                    ? null
                    : () => setState(
                        () => cart[product['id'] as int] =
                            (cart[product['id'] as int] ?? 0) + 1,
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(108, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(
                  '₹${_price(product).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productActionButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required Color foreground,
    required Color background,
    required VoidCallback onPressed,
  }) => IconButton(
    key: key,
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 34, height: 32),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    icon: Icon(icon, size: 17),
  );

  Future<void> _scanBarcode() async {
    final code = await showBarcodeScanner(context);
    if (!mounted || code == null || code.trim().isEmpty) return;
    search.text = code.trim();
    search.selection = TextSelection.collapsed(offset: search.text.length);
    setState(() {});
  }

  Future<void> _editProductPrice(Map<String, dynamic> product) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditBillingPriceDialog(
        state: widget.state,
        product: product,
        initialPrice: _price(product),
      ),
    );
    if (saved == true && mounted) {
      setState(() {});
      showNotice(context, 'Selling price updated.');
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: red,
              size: 38,
            ),
            title: const Text('Delete product?'),
            content: Text(
              '${product['name']} will be permanently removed from the catalogue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: red),
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await widget.state.deleteProduct(product['id'] as int);
      if (!mounted) return;
      setState(() => cart.remove(product['id']));
      showNotice(context, 'Product deleted.');
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    }
  }

  Widget _cart() => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      TextButton.icon(
        onPressed: () => setState(cart.clear),
        icon: const Icon(Icons.add),
        label: const Text('Add another product'),
      ),
      for (final entry in cart.entries)
        Builder(
          builder: (_) {
            final product = _product(entry.key);
            final stock =
                int.tryParse(product['stock_quantity'].toString()) ?? 0;
            return SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '₹${_price(product).toStringAsFixed(2)} × ${entry.value}',
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      if (entry.value <= 1) {
                        cart.remove(entry.key);
                      } else {
                        cart[entry.key] = entry.value - 1;
                      }
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: entry.value >= stock
                        ? null
                        : () =>
                              setState(() => cart[entry.key] = entry.value + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            );
          },
        ),
    ],
  );

  Widget _checkoutBar(BuildContext context) => Material(
    elevation: 12,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal ₹${subtotal.toStringAsFixed(2)}'),
              Text('GST ₹${gst.toStringAsFixed(2)}'),
              Text(
                'Total ₹${(subtotal + gst).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  items: const [
                    DropdownMenuItem(value: 'upi', child: Text('GPAY / UPI')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                  ],
                  onChanged: (value) =>
                      setState(() => paymentMethod = value ?? 'upi'),
                  decoration: const InputDecoration(labelText: 'Payment'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: submitting ? null : _pay,
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_outline),
                  label: const Text('Pay securely'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _pay() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => submitting = true);
    try {
      final invoice = await widget.state.checkout(
        items: [
          for (final entry in cart.entries)
            {'product': _product(entry.key), 'quantity': entry.value},
        ],
        paymentMethod: paymentMethod,
        customerMobile: mobile.text,
      );
      if (!mounted) return;
      setState(cart.clear);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: green, size: 48),
          title: const Text('Payment Successful'),
          content: Text(
            'Invoice ${invoice['number']}\nGrand Total ₹${invoice['total']}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('New Bill'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}
