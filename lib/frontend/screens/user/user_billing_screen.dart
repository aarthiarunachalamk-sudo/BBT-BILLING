part of 'user_screens.dart';

class UserBillingScreen extends StatelessWidget {
  const UserBillingScreen(this.state, {super.key});

  final UserState state;

  @override
  Widget build(BuildContext context) => UserShell(
    state: state,
    title: 'Billing / POS',
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: state.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search or scan product',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.qr_code_scanner),
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: state.visibleProducts.isEmpty
              ? const EmptyMessage('No available products.')
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: state.visibleProducts.length,
                  itemBuilder: (_, index) {
                    final product = state.visibleProducts[index];
                    final quantity = number(
                      product['total_stock'] ?? product['stock_quantity'],
                    );
                    return SizedBox(
                      width: 150,
                      child: UserCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () => state.addProduct(product),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: UserProductImage(
                                imageUrl: product['image']?.toString(),
                                quantity: quantity,
                                size: 70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${product['name']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              money(product['selling_price']),
                              style: const TextStyle(
                                color: userBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '$quantity available',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
