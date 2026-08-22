part of 'user_screens.dart';

class UserBillingScreen extends StatelessWidget {
  const UserBillingScreen(this.state, {super.key});

  final UserState state;

  @override
  Widget build(BuildContext context) => UserShell(
    state: state,
    title: 'Billing / POS',
    child: Column(children: [
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
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Subtotal'), Text(money(state.subtotal))],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Estimated GST'), Text(money(state.gst))],
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
          ElevatedButton(
            onPressed: state.cart.isEmpty
                ? null
                : () => state.go(UserPage.payment, load: false),
            child: const Text('Proceed to Payment'),
          ),
        ]),
      ),
    ]),
  );
}
