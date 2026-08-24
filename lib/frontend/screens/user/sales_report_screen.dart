part of 'user_screens.dart';

class SalesReportScreen extends StatefulWidget { const SalesReportScreen(this.state, {super.key}); final UserState state; @override State<SalesReportScreen> createState() => _SalesReportScreenState(); }
class _SalesReportScreenState extends State<SalesReportScreen> { String range = 'today';
  Future<void> load(String value) async { setState(() => range = value); widget.state.loading = true; widget.state.notifyListeners(); try { widget.state.paymentSummary = await widget.state.api.getMap('payments/summary', query: {'range': value}); } on UserApiException catch (e) { widget.state.error = e.message; } finally { widget.state.loading = false; widget.state.notifyListeners(); } }
  @override Widget build(BuildContext context) { final d = widget.state.paymentSummary; final rows = (d['payment_breakdown'] as List?)?.whereType<Map>().toList() ?? []; return UserShell(state: widget.state, title: 'Payment & Sales Report', child: ListView(padding: const EdgeInsets.all(14), children: [
    UserFilterTabs(values: const ['Today', 'Yesterday', 'Week', 'Month'], selected: range[0].toUpperCase() + range.substring(1), onSelected: (value) => load(value.toLowerCase())), const SizedBox(height: 12),
    Row(children: [Expanded(child: SummaryTile(label: 'Total Sales', value: money(d['total_sales']), icon: Icons.currency_rupee, color: userGreen)), const SizedBox(width: 8), Expanded(child: SummaryTile(label: 'Transactions', value: '${d['total_transactions'] ?? 0}', icon: Icons.receipt_long, color: userBlue))]), const SizedBox(height: 14),
    const Text('Payment Breakdown', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), if (rows.isEmpty) const SizedBox(height: 180, child: EmptyMessage('No completed payments in this period.')) else for (final row in rows) UserCard(child: Row(children: [const Icon(Icons.payments_outlined, color: userBlue), const SizedBox(width: 12), Expanded(child: Text('${row['method']}'.toUpperCase())), Text(money(row['total']), style: const TextStyle(fontWeight: FontWeight.w800))])),
  ])); }
}
