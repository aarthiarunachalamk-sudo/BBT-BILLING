part of 'user_screens.dart';

class UserBillingScreen extends StatefulWidget {
  const UserBillingScreen(this.state, {super.key});

  final UserState state;

  @override
  State<UserBillingScreen> createState() => _UserBillingScreenState();
}

class _UserBillingScreenState extends State<UserBillingScreen> {
  final search = TextEditingController();

  UserState get state => widget.state;

  @override
  void initState() {
    super.initState();
    search.text = state.search;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UserShell(
    state: state,
    title: 'Billing / POS',
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: search,
            onChanged: state.setSearch,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: userBlue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: userBlue,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${state.visibleProducts.length} products available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: userNavy,
                  ),
                ),
              ),
              if (state.cart.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                  label: Text('Clear (${state.cart.length})'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: state.cart.isEmpty ? 300 : 220,
          child: state.visibleProducts.isEmpty
              ? const EmptyMessage('No products found.')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: state.visibleProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) =>
                      _catalogProductCard(state.visibleProducts[index]),
                ),
        ),
        const Divider(),
        Expanded(
          child: state.cart.isEmpty
              ? const EmptyMessage('Scan or tap a product to start a bill.')
              : ListView.builder(
                  itemCount: state.cart.length,
                  itemBuilder: (_, index) {
                    final line = state.cart[index];
                    return ListTile(
                      leading: UserProductImage(
                        imageUrl: line.product['image']?.toString(),
                        quantity: line.quantity,
                        size: 44,
                      ),
                      title: Text(line.name),
                      subtitle: Text(
                        '${money(line.price)} × ${line.quantity} = ${money(line.total)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => state.changeQuantity(line, -1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${line.quantity}'),
                          IconButton(
                            onPressed: () => state.changeQuantity(line, 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('Subtotal'), Text(money(state.subtotal))],
              ),
              if (state.discountPercent > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount (${state.discountPercent.toStringAsFixed(1)}%)',
                    ),
                    Text(
                      '- ${money(state.discountAmount)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated GST'),
                  Text(money(state.discountedGst)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                  Text(
                    money(state.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.discountApproval.isNotEmpty) ...[
                _DiscountStatusCard(state),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.cart.isEmpty || state.loading
                          ? null
                          : state.discountApproved
                          ? state.removeDiscount
                          : () => _requestBillingDiscount(context, state),
                      icon: Icon(
                        state.discountApproved
                            ? Icons.close_rounded
                            : Icons.discount_outlined,
                      ),
                      label: Text(
                        state.discountApproved
                            ? 'Remove Discount'
                            : state.discountPending
                            ? 'Check Approval'
                            : 'Request Discount',
                      ),
                    ),
                  ),
                  if (state.discountPending) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Refresh approval status',
                      onPressed: state.loading
                          ? null
                          : () async {
                              final updated = await state
                                  .refreshDiscountApproval();
                              if (context.mounted) {
                                _notice(
                                  context,
                                  updated
                                      ? state.discountApproved
                                            ? 'Discount approved. You can continue payment.'
                                            : state.discountStatus == 'rejected'
                                            ? 'The discount request was rejected.'
                                            : 'Approval is still pending.'
                                      : state.error ??
                                            'Could not refresh approval.',
                                );
                              }
                            },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: state.cart.isEmpty || state.discountPending
                    ? null
                    : () => state.go(UserPage.payment, load: false),
                child: Text(
                  state.discountPending
                      ? 'Waiting for Admin Approval'
                      : 'Proceed to Payment',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _catalogProductCard(Map<String, dynamic> product) {
    final quantity = number(
      product['total_stock'] ?? product['stock_quantity'],
    );
    final id = int.tryParse('${product['id']}');
    return UserCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          UserProductImage(
            imageUrl: product['image']?.toString(),
            quantity: quantity,
            size: 58,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['name']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product['sku'] ?? product['barcode'] ?? 'No SKU'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                ),
                const SizedBox(height: 5),
                StatusPill(
                  quantity > 0 ? '$quantity in stock' : 'Out of stock',
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (state.canManageInventory && id != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      key: ValueKey('user-billing-edit-product-$id'),
                      tooltip: 'Edit price',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _editProductPrice(product),
                      icon: const Icon(Icons.edit_rounded, size: 17),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      key: ValueKey('user-billing-delete-product-$id'),
                      tooltip: 'Delete product',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _deleteProduct(product),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: userRed,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 5),
              FilledButton.icon(
                key: ValueKey('user-billing-add-product-$id'),
                onPressed: quantity <= 0
                    ? null
                    : () => state.addProduct(product),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(
                  money(product['selling_price']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final code = await showBarcodeScanner(context);
    if (!mounted || code == null || code.trim().isEmpty) return;
    final value = code.trim();
    search.text = value;
    search.selection = TextSelection.collapsed(offset: value.length);
    state.setSearch(value);
    final exact = state.products.where(
      (product) => [product['barcode'], product['sku']].any(
        (candidate) =>
            candidate?.toString().trim().toLowerCase() == value.toLowerCase(),
      ),
    );
    if (exact.length == 1) {
      state.addProduct(exact.first);
      if (mounted) _notice(context, '${exact.first['name']} added to bill.');
    }
  }

  void _clearCart() {
    state.clearCart();
    search.clear();
    state.setSearch('');
  }

  Future<void> _editProductPrice(Map<String, dynamic> product) async {
    final controller = TextEditingController(
      text: (double.tryParse('${product['selling_price']}') ?? 0)
          .toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update selling price'),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const Key('user-billing-price-field'),
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Selling price',
              prefixText: '₹ ',
            ),
            validator: (text) {
              final price = double.tryParse(text?.trim() ?? '');
              return price == null || price <= 0
                  ? 'Enter a valid price greater than zero'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save price'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final id = int.tryParse('${product['id']}');
    if (id == null) return;
    final saved = await state.updateProduct(id, {'selling_price': value});
    if (mounted) {
      _notice(
        context,
        saved ? 'Selling price updated.' : state.error ?? 'Update failed.',
      );
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: userRed,
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
            style: FilledButton.styleFrom(backgroundColor: userRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = int.tryParse('${product['id']}');
    if (id == null) return;
    final deleted = await state.deleteProduct(id);
    if (mounted) {
      _notice(
        context,
        deleted ? 'Product deleted.' : state.error ?? 'Delete failed.',
      );
    }
  }
}

class _DiscountStatusCard extends StatelessWidget {
  const _DiscountStatusCard(this.state);
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final status = state.discountStatus;
    final color = switch (status) {
      'approved' || 'not_required' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
    final label = switch (status) {
      'approved' => 'Approved by Admin',
      'not_required' => 'Within Cashier Limit',
      'rejected' => 'Rejected by Admin',
      _ => 'Waiting for Admin Approval',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${state.discountApproval['requested_percent'] ?? state.discountPercent}% discount',
                  style: const TextStyle(fontSize: 11),
                ),
                if ('${state.discountApproval['review_note'] ?? ''}'
                    .trim()
                    .isNotEmpty)
                  Text(
                    '${state.discountApproval['review_note']}',
                    style: const TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _requestBillingDiscount(
  BuildContext context,
  UserState state,
) async {
  if (state.discountPending) {
    final updated = await state.refreshDiscountApproval();
    if (context.mounted) {
      _notice(
        context,
        updated
            ? state.discountApproved
                  ? 'Discount approved. You can continue payment.'
                  : state.discountStatus == 'rejected'
                  ? 'The discount request was rejected.'
                  : 'Approval is still pending.'
            : state.error ?? 'Could not refresh approval.',
      );
    }
    return;
  }
  final percent = TextEditingController();
  final reason = TextEditingController();
  final request = await showDialog<(double, String)>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Request Bill Discount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: percent,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Discount percentage',
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason for discount',
              hintText: 'Example: Loyal customer',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(percent.text.trim());
            if (value == null || value <= 0 || value > 100) return;
            Navigator.pop(dialogContext, (value, reason.text.trim()));
          },
          child: const Text('Submit Request'),
        ),
      ],
    ),
  );
  percent.dispose();
  reason.dispose();
  if (request == null) return;
  final submitted = await state.requestDiscount(request.$1, request.$2);
  if (context.mounted) {
    _notice(
      context,
      submitted
          ? state.discountApproved
                ? 'Discount applied within your cashier limit.'
                : 'Discount request sent to the admin.'
          : state.error ?? 'Could not request discount.',
    );
  }
}
