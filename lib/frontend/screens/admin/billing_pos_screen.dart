part of 'admin_screens.dart';

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
            decoration: const InputDecoration(
              hintText: 'Scan barcode / search product or SKU',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.qr_code_scanner),
            ),
          ),
        ),
        Expanded(child: cart.isEmpty ? _catalog() : _cart()),
        if (cart.isNotEmpty) _checkoutBar(context),
      ],
    ),
  );

  Widget _catalog() => products.isEmpty
      ? const _EmptyState(
          'No products found.',
          icon: Icons.inventory_2_outlined,
        )
      : ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final product = products[index];
            final stock =
                int.tryParse(product['stock_quantity'].toString()) ?? 0;
            return SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: product['image']?.toString().isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image'],
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.inventory_2),
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined),
                title: Text(product['name'].toString(), maxLines: 1),
                subtitle: Text('${product['sku']} • Stock $stock'),
                trailing: FilledButton(
                  onPressed: stock <= 0
                      ? null
                      : () => setState(() => cart[product['id'] as int] = 1),
                  child: Text('₹${_price(product).toStringAsFixed(2)}  +'),
                ),
              ),
            );
          },
        );

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
