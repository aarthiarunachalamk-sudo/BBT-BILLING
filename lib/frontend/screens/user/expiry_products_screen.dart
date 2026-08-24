part of 'user_screens.dart';

class ExpiryProductsScreen extends StatelessWidget {
  const ExpiryProductsScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final limit = switch (state.expiryFilter) {'Expired' => -1, '7 Days' => 7, '30 Days' => 30, _ => 90};
    final today = DateTime.now();
    final rows = state.batches.where((batch) {
      final date = DateTime.tryParse('${batch['expiry_date']}');
      if (date == null) return false;
      final days = date.difference(DateTime(today.year, today.month, today.day)).inDays;
      return limit == -1 ? days < 0 : days >= 0 && days <= limit;
    }).toList();
    return UserShell(
      state: state,
      title: 'Expiry Products',
      showBack: true,
      child: Column(children: [
        UserFilterTabs(values: const ['Expired', '7 Days', '30 Days', '90 Days'], selected: state.expiryFilter, onSelected: state.setExpiryFilter),
        Expanded(
          child: rows.isEmpty
              ? const EmptyMessage('No batches match this expiry window.')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  itemBuilder: (_, index) {
                    final batch = rows[index];
                    final date = DateTime.parse('${batch['expiry_date']}');
                    final days = date.difference(DateTime(today.year, today.month, today.day)).inDays;
                    return UserCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(batch['item_name']?.toString() ?? 'Product #${batch['item']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                          StatusPill(days < 0 ? 'Expired' : '$days days'),
                        ]),
                        Text('Batch ${batch['batch_number']}  •  Quantity ${number(batch['quantity'])}'),
                        Text('Expiry: ${date.day}/${date.month}/${date.year}'),
                        Wrap(
                          spacing: 5,
                          children: const [
                            ('Remove from Shelf', 'remove-from-shelf'),
                            ('Clearance', 'clearance'),
                            ('Return Supplier', 'return-supplier'),
                            ('Dispose', 'dispose'),
                          ].map((action) => TextButton(
                            onPressed: state.loading ? null : () => _runAction(context, batch, action.$1, action.$2),
                            child: Text(action.$1, style: const TextStyle(fontSize: 11)),
                          )).toList(),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Future<void> _runAction(BuildContext context, Map<String, dynamic> batch, String label, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$label?'),
        content: Text('Apply this action to batch ${batch['batch_number']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    final success = await state.updateBatchStatus(batch['id'] as int, action);
    if (context.mounted) _notice(context, success ? '$label completed.' : state.error ?? '$label failed.');
  }
}
