part of '../admin_screens.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  String method = 'Cash';
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Returns & Refunds',
    back: 14,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SearchBox('Search invoice'),
              const SizedBox(height: 10),
              const Text(
                'BILL-2025-0138',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 15),
              const Text(
                'Items Returned',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const _TableHeader(['Item', 'Qty', 'Amount (â‚¹)']),
              const _TableRow(['Fortune Oil 1L', '1', '160.00']),
              const _TableRow(['Tata Salt 1kg', '1', '18.00']),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: 'Wrong item purchased',
                decoration: const InputDecoration(labelText: 'Return Reason'),
                items: ['Wrong item purchased', 'Damaged item', 'Expired item']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: '178.00',
                decoration: const InputDecoration(
                  labelText: 'Refund Amount (â‚¹)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Refund Method',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              ...[
                'Cash',
                'Original Payment',
                'Store Credit',
                'Replacement',
              ].map(
                (v) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onTap: () => setState(() => method = v),
                  leading: Icon(
                    method == v
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: method == v ? blue : muted,
                    size: 20,
                  ),
                  title: Text(v, style: const TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            'Approve Refund',
            onPressed: () async {
              try {
                await widget.state.approveReturn(method);
                if (context.mounted) {
                  showNotice(context, 'Refund approved via $method');
                }
              } catch (error) {
                if (context.mounted) showNotice(context, error.toString());
              }
            },
          ),
        ),
      ],
    ),
  );
}
