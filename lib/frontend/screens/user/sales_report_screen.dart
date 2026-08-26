part of 'user_screens.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen(this.state, {super.key});
  final UserState state;

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  String range = 'today';

  Future<void> load(String value) async {
    setState(() => range = value);
    widget.state.loading = true;
    widget.state.notify();
    try {
      widget.state.paymentSummary = await widget.state.api.getMap('payments/summary', query: {'range': value});
      widget.state.invoices = await widget.state.api.getList('invoices');
    } on UserApiException catch (error) {
      widget.state.error = error.message;
    } finally {
      widget.state.loading = false;
      widget.state.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.state.paymentSummary;
    final breakdown = (data['payment_breakdown'] as List?)?.whereType<Map>().toList() ?? const [];
    return UserShell(
      state: widget.state,
      title: 'Payment & Sales Report',
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          UserFilterTabs(
            values: const ['Today', 'Yesterday', 'Week', 'Month'],
            selected: range[0].toUpperCase() + range.substring(1),
            onSelected: (value) => load(value.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SummaryTile(label: 'Total Sales', value: money(data['total_sales']), icon: Icons.currency_rupee, color: userGreen)),
              const SizedBox(width: 8),
              Expanded(child: SummaryTile(label: 'Transactions', value: '${data['total_transactions'] ?? 0}', icon: Icons.receipt_long, color: userBlue)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Payment Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          if (breakdown.isEmpty)
            const SizedBox(height: 110, child: EmptyMessage('No completed payments in this period.'))
          else
            for (final row in breakdown)
              UserCard(
                child: Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: userBlue),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${row['method']}'.toUpperCase())),
                    Text('${row['count'] ?? 0} transactions', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                    const SizedBox(width: 10),
                    Text(money(row['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          const Text('Bill History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          if (widget.state.invoices.isEmpty)
            const UserCard(child: Text('Your completed bills will appear here.'))
          else
            for (final invoice in widget.state.invoices.take(20))
              UserCard(
                onTap: () {
                  widget.state.lastInvoice = invoice;
                  widget.state.go(UserPage.invoice, load: false);
                },
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: userBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${invoice['number'] ?? 'Invoice'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${invoice['invoice_date'] ?? invoice['created_at'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(money(invoice['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
                        StatusPill('${invoice['status'] ?? 'paid'}'),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

