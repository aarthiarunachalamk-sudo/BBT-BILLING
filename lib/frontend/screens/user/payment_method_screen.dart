part of 'user_screens.dart';

class PaymentMethodScreen extends StatefulWidget { const PaymentMethodScreen(this.state, {super.key}); final UserState state; @override State<PaymentMethodScreen> createState() => _PaymentMethodScreenState(); }
class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String method = 'upi'; final cash = TextEditingController(), upi = TextEditingController(), card = TextEditingController();
  @override void dispose() { cash.dispose(); upi.dispose(); card.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => UserShell(state: widget.state, title: 'Payment Method', child: ListView(padding: const EdgeInsets.all(16), children: [
    UserCard(child: Column(children: [const Text('Amount Payable'), Text(money(widget.state.grandTotal), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: userNavy))])), const SizedBox(height: 10),
    for (final item in [('upi', 'GPay / UPI', Icons.qr_code), ('cash', 'Cash', Icons.payments_outlined), ('card', 'Card', Icons.credit_card), ('split', 'Split Payment', Icons.call_split)])
      UserCard(onTap: () => setState(() => method = item.$1), child: Row(children: [Radio<String>(value: item.$1, groupValue: method, onChanged: (v) => setState(() => method = v!)), Icon(item.$3, color: userBlue), const SizedBox(width: 10), Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700))])),
    if (method == 'split') ...[const SizedBox(height: 10), TextField(controller: cash, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash amount')), const SizedBox(height: 8), TextField(controller: upi, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'UPI amount')), const SizedBox(height: 8), TextField(controller: card, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Card amount'))],
    const SizedBox(height: 18), ElevatedButton(onPressed: widget.state.loading ? null : _pay, child: Text('Pay ${money(widget.state.grandTotal)}')),
  ]));
  Future<void> _pay() async { List<Map<String, dynamic>> payments; if (method == 'split') { payments = [('cash', cash.text), ('upi', upi.text), ('card', card.text)].where((e) => (double.tryParse(e.$2) ?? 0) > 0).map((e) => {'method': e.$1, 'amount': double.parse(e.$2)}).toList(); final total = payments.fold<double>(0, (s, p) => s + (p['amount'] as double)); if ((total - widget.state.grandTotal).abs() > .01) { _notice(context, 'Split payment must exactly equal ${money(widget.state.grandTotal)}.'); return; } } else { payments = [{'method': method, 'amount': double.parse(widget.state.grandTotal.toStringAsFixed(2))}]; } await widget.state.checkout(payments); }
}
