part of 'admin_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Admin Dashboard',
    actions: [
      _PaymentNotificationButton(state: state),
    ],
    child: RefreshIndicator(
      onRefresh: state.refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          _ReferenceSummaryGrid(state),
          const SizedBox(height: 10),
          _ReferencePaymentSummary(state),
        ],
      ),
    ),
  );
}

class _ReferenceSummaryGrid extends StatelessWidget {
  const _ReferenceSummaryGrid(this.state);
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final data = state.dashboard;
    final cards =
        <
          ({
            String title,
            String value,
            String note,
            Color color,
            IconData icon,
            VoidCallback tap,
          })
        >[
          (
            title: "Today's Sales",
            value: _money(data['today_sales']),
            note: '${data['sales_growth'] ?? 0}% vs yesterday',
            color: green,
            icon: Icons.currency_rupee_rounded,
            tap: () => state.go(17),
          ),
          (
            title: 'Total Bills',
            value: '${data['total_bills'] ?? 0}',
            note: '${data['bills_growth'] ?? 0}% vs yesterday',
            color: blue,
            icon: Icons.receipt_long_outlined,
            tap: () => state.go(13),
          ),
          (
            title: 'Profit',
            value: _money(data['profit']),
            note: '${data['profit_growth'] ?? 0}% vs yesterday',
            color: green,
            icon: Icons.trending_up_rounded,
            tap: () => state.go(17),
          ),
          (
            title: 'Low Stock',
            value: '${data['low_stock_count'] ?? 0}',
            note: 'Items need attention',
            color: const Color(0xFFF59E0B),
            icon: Icons.inventory_2_outlined,
            tap: () {
              state.setInventoryFilter('Low Stock');
              state.go(9);
            },
          ),
          (
            title: 'Expiring Soon',
            value: '${data['expiring_soon_count'] ?? 0}',
            note: 'Within 30 days',
            color: const Color(0xFFF97316),
            icon: Icons.event_busy_outlined,
            tap: () {
              state.setInventoryFilter('Expiring');
              state.go(9);
            },
          ),
          (
            title: 'Out of Stock',
            value: '${data['out_of_stock_count'] ?? 0}',
            note: 'Restock required',
            color: red,
            icon: Icons.warning_amber_rounded,
            tap: () {
              state.setInventoryFilter('Out of Stock');
              state.go(9);
            },
          ),
        ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: constraints.maxWidth < 560 ? 1.62 : 1.9,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _ReferenceMetricCard(
              title: card.title,
              value: card.value,
              note: card.note,
              color: card.color,
              icon: card.icon,
              onTap: card.tap,
            );
          },
        );
      },
    );
  }
}

class _ReferenceMetricCard extends StatelessWidget {
  const _ReferenceMetricCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final String title, value, note;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: title == 'Low Stock' || title == 'Out of Stock'
                    ? color
                    : navy,
              fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReferencePaymentSummary extends StatelessWidget {
  const _ReferencePaymentSummary(this.state);
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final rows = (state.dashboard['payment_breakdown'] as List? ?? const []);
    double amount(String method) => rows
        .where((row) => row is Map && row['method'] == method)
        .fold(
          0,
          (sum, row) =>
              sum + (double.tryParse('${(row as Map)['total']}') ?? 0),
        );
    final upi = amount('upi');
    final cash = amount('cash');
    final card = amount('card');
    final razorpay = amount('razorpay');
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Payments",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _paymentRow(
            Icons.account_balance_wallet_outlined,
            'GPay / UPI',
            upi,
            green,
          ),
          _paymentRow(
            Icons.payments_outlined,
            'Cash',
            cash,
            const Color(0xFFF59E0B),
          ),
          _paymentRow(
            Icons.credit_card_outlined,
            'Card',
            card,
            const Color(0xFF7C3AED),
          ),
          _paymentRow(
            Icons.account_balance_wallet_rounded,
            'Razorpay',
            razorpay,
            blue,
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Collection',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _money(upi + cash + card + razorpay),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(IconData icon, String label, double value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _money(value),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _Welcome extends StatelessWidget {
  const _Welcome(this.state);
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                state.storeSettings['store_name']?.toString() ??
                    'BBT Supermarket',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        _PaymentNotificationButton(state: state, filled: true),
      ],
    );
  }
}

class _PaymentNotificationButton extends StatelessWidget {
  const _PaymentNotificationButton({required this.state, this.filled = false});
  final AdminState state;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final hasNotifications = state.paymentNotifications.isNotEmpty;
    final icon = Stack(children: [
      if (filled)
        IconButton.filledTonal(onPressed: () => _showPaymentNotifications(context, state), icon: const Icon(Icons.notifications_none_rounded))
      else
        IconButton(onPressed: () => _showPaymentNotifications(context, state), icon: const Icon(Icons.notifications_none_rounded)),
      if (hasNotifications)
        Positioned(right: 7, top: 7, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: red, shape: BoxShape.circle))),
    ]);
    return icon;
  }
}

Future<void> _showPaymentNotifications(BuildContext context, AdminState state) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(child: ListView(shrinkWrap: true, children: [
    const ListTile(leading: Icon(Icons.payments_outlined, color: green), title: Text('Payment Notifications', style: TextStyle(fontWeight: FontWeight.w900))),
    if (state.paymentNotifications.isEmpty)
      const ListTile(title: Text('No user payments received yet.')),
    for (final notice in state.paymentNotifications.take(20))
      ListTile(
        leading: const Icon(Icons.check_circle_outline, color: green),
        title: Text('Payment received${(notice['metadata'] as Map?)?['invoice_number'] == null ? '' : ' • ${(notice['metadata'] as Map)['invoice_number']}'}'),
        subtitle: Text('${notice['user_name'] ?? 'User'} • ${_dateText(notice['created_at'])}'),
        trailing: Text('₹${(notice['metadata'] as Map?)?['amount'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
  ])),
);

class _Revenue extends StatelessWidget {
  const _Revenue(this.data, this.tap);
  final Map<String, dynamic> data;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) {
    final growth = double.tryParse('${data['sales_growth'] ?? 0}') ?? 0;
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF164E8C), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x302563EB),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: 0,
              width: 160,
              height: 85,
              child: CustomPaint(
                painter: _TrendPainter(
                  _trend(data),
                  Colors.white.withValues(alpha: .75),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      "TODAY'S REVENUE",
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _money(data['today_sales']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      growth < 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: growth < 0
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF86EFAC),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${growth.abs().toStringAsFixed(1)}% compared with yesterday',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashTitle extends StatelessWidget {
  const _DashTitle(this.title, this.subtitle, {this.action, this.tap});
  final String title, subtitle;
  final String? action;
  final VoidCallback? tap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
      if (action != null) TextButton(onPressed: tap, child: Text(action!)),
    ],
  );
}

class _Kpis extends StatelessWidget {
  const _Kpis(this.data);
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final values = [
      (
        'Bills',
        '${data['total_bills'] ?? 0}',
        Icons.receipt_long_outlined,
        blue,
        _growth(data['bills_growth']),
      ),
      (
        'Profit',
        _money(data['profit']),
        Icons.account_balance_wallet_outlined,
        green,
        _growth(data['profit_growth']),
      ),
      (
        'Customers',
        '${data['customer_count'] ?? 0}',
        Icons.groups_2_outlined,
        const Color(0xFF7C3AED),
        'Active',
      ),
      (
        'Products sold',
        '${data['products_sold'] ?? 0}',
        Icons.shopping_bag_outlined,
        const Color(0xFF0891B2),
        'Today',
      ),
      (
        'Avg. bill',
        _money(data['average_bill_value']),
        Icons.analytics_outlined,
        const Color(0xFFEA580C),
        'Today',
      ),
      (
        'Low stock',
        '${data['low_stock_count'] ?? 0}',
        Icons.warning_amber_rounded,
        red,
        'Needs action',
      ),
    ];
    return LayoutBuilder(
      builder: (_, box) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: values.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: box.maxWidth >= 850 ? 3 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 128,
        ),
        itemBuilder: (_, i) {
          final item = values[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: item.$4.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.$3, color: item.$4, size: 18),
                    ),
                    const Spacer(),
                    Text(
                      item.$5,
                      style: TextStyle(
                        color: item.$4,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart(this.data);
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashTitle('Sales overview', 'Last 7 days'),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(_trend(data), blue, fill: true),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Mini('Revenue', _money(data['today_sales'])),
            _Mini('Profit', _money(data['profit'])),
            _Mini('Bills', '${data['total_bills'] ?? 0}'),
          ],
        ),
      ],
    ),
  );
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: muted)),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions(this.state);
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.receipt_long_outlined, 'Sales', 10),
      (Icons.add_box_outlined, 'Add product', 5),
      (Icons.qr_code_scanner_rounded, 'Scan', 4),
      (Icons.local_shipping_outlined, 'Supplier', 7),
      (Icons.shopping_cart_checkout_rounded, 'Purchase', 8),
      (Icons.person_add_alt_1_outlined, 'Add user', 2),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashTitle('Quick actions', 'Everything important, one tap away'),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => InkWell(
              onTap: () => state.go(items[i].$3),
              borderRadius: BorderRadius.circular(17),
              child: Container(
                width: 88,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(items[i].$1, color: blue, size: 18),
                    ),
                    const Spacer(),
                    Text(
                      items[i].$2,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Approvals extends StatelessWidget {
  const _Approvals(this.state);
  final AdminState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _DashTitle('Approvals', 'Items waiting for your decision'),
      const SizedBox(height: 10),
      _Action(
        Icons.percent_rounded,
        const Color(0xFFF59E0B),
        'Discount requests',
        '${state.dashboard['pending_discount_approvals'] ?? 0} pending',
        () => state.go(11),
      ),
      const SizedBox(height: 10),
      _Action(
        Icons.shopping_cart_checkout_rounded,
        blue,
        'Purchase orders',
        '${state.dashboard['pending_purchase_orders'] ?? 0} pending',
        () => state.go(8),
      ),
    ],
  );
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.color, this.title, this.subtitle, this.tap);
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    ),
  );
}

class _LowStock extends StatelessWidget {
  const _LowStock(this.state);
  final AdminState state;
  @override
  Widget build(BuildContext context) {
    final items = (state.dashboard['low_stock_products'] as List? ?? const [])
        .cast<Map>();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashTitle(
            'Low stock alert',
            '${state.dashboard['low_stock_count'] ?? 0} products need attention',
            action: 'View all',
            tap: () => state.go(9),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const _Empty('All products have sufficient stock')
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${item['name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${item['stock_quantity']} left',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts(this.data);
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final items = (data['top_products'] as List? ?? const []).cast<Map>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashTitle('Top products', 'Best sellers this week'),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const _Empty('Sales will appear here')
          else
            for (var i = 0; i < items.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  '${items[i]['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${items[i]['quantity']} units sold'),
                trailing: Text(
                  _money(items[i]['revenue']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
        ],
      ),
    );
  }
}

class _PaymentAnalysis extends StatelessWidget {
  const _PaymentAnalysis(this.data);
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final rows = (data['payment_breakdown'] as List? ?? const []).cast<Map>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashTitle('Payment analysis', 'Verified collections by mode'),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _Empty('No payment data yet')
          else
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                for (var i = 0; i < rows.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: [
                            blue,
                            const Color(0xFF06B6D4),
                            const Color(0xFF7C3AED),
                            green,
                          ][i % 4],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${rows[i]['method']}'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _money(rows[i]['total']),
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentBills extends StatelessWidget {
  const _RecentBills(this.data);
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final bills = (data['recent_invoices'] as List? ?? const []).cast<Map>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashTitle('Recent bills', 'Latest customer transactions'),
          const SizedBox(height: 8),
          if (bills.isEmpty)
            const _Empty('No bills created yet')
          else
            for (final bill in bills.take(4))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFECFDF5),
                  child: Icon(Icons.receipt_outlined, color: green, size: 19),
                ),
                title: Text(
                  '${bill['number']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${bill['client_name'] ?? 'Walk-in customer'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _money(bill['total']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(text, style: const TextStyle(color: muted)),
    ),
  );
}

List<double> _trend(Map<String, dynamic> data) =>
    (data['sales_trend'] as List? ?? const [])
        .map((row) => double.tryParse('${(row as Map)['total']}') ?? 0)
        .toList();

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.values, this.color, {this.fill = false});
  final List<double> values;
  final Color color;
  final bool fill;
  @override
  void paint(Canvas canvas, Size size) {
    final data = values.isEmpty ? <double>[1, 3, 2, 5, 4, 8, 7] : values;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1 ? 0.0 : size.width * i / (data.length - 1);
      final y =
          size.height -
          (maxValue == 0
              ? size.height / 2
              : data[i] / maxValue * (size.height - 12)) -
          6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: .2), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.title,
    this.value,
    this.note,
    this.noteColor, [
    this.valueColor = ink,
  ]);
  final String title, value, note;
  final Color valueColor, noteColor;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: muted)),
        const Spacer(),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
        Text(
          note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, color: noteColor),
        ),
      ],
    ),
  );
}

String _money(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '') ?? 0;
  return '₹ ${amount.toStringAsFixed(2)}';
}

Color _growthTone(dynamic value) =>
    (double.tryParse(value?.toString() ?? '') ?? 0) < 0 ? red : green;
String _percent(dynamic value, int fallback) =>
    '${double.tryParse(value?.toString() ?? '')?.round() ?? fallback}%';
