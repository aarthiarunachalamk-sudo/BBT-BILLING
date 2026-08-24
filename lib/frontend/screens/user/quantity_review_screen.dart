part of 'user_screens.dart';

class QuantityReviewScreen extends StatelessWidget {
  const QuantityReviewScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final rows = state.reviews.where((row) =>
      state.reviewFilter == 'All' || '${row['status']}'.toLowerCase() == state.reviewFilter.toLowerCase()).toList();
    return UserShell(state: state, title: 'Quantity Review — 14 Days', showBack: true, child: Column(children: [
      SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.all(6), children: [
        for (final filter in ['All', 'Due', 'Updated', 'Overdue']) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: ChoiceChip(label: Text(filter), selected: state.reviewFilter == filter, onSelected: (_) => state.setReviewFilter(filter))),
      ])),
      Expanded(child: rows.isEmpty ? const EmptyMessage('No quantity reviews match this filter.') : ListView.builder(padding: const EdgeInsets.all(12), itemCount: rows.length, itemBuilder: (_, index) {
        final row = rows[index];
        final difference = number(row['physical_quantity']) - number(row['system_quantity']);
        return UserCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text('Product #${row['item']}', style: const TextStyle(fontWeight: FontWeight.w800))), StatusPill('${row['status']}')]),
          const SizedBox(height: 8), Text('System: ${number(row['system_quantity'])}  •  Physical: ${number(row['physical_quantity'])}  •  Difference: $difference'),
          Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
            TextButton(onPressed: state.loading ? null : () => _recordReview(context, row), child: const Text('Update Quantity')),
            TextButton(onPressed: state.loading ? null : () => _confirmSystemStock(context, row), child: const Text('Confirm Stock')),
            TextButton(onPressed: state.loading ? null : () => _recordReview(context, row, reportDifference: true), child: const Text('Report Difference')),
          ]),
        ]));
      })),
      if (rows.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(children: [
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: state.loading ? null : () => _recordReview(context, rows.first), child: const Text('Update Quantity'))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: userGreen), onPressed: state.loading ? null : () => _confirmSystemStock(context, rows.first), child: const Text('Confirm Stock'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: userRed), onPressed: state.loading ? null : () => _recordReview(context, rows.first, reportDifference: true), child: const Text('Report Difference'))),
            ]),
          ]),
        ),
    ]));
  }

  Future<void> _recordReview(BuildContext context, Map<String, dynamic> row, {bool reportDifference = false}) async {
    final controller = TextEditingController();
    final physical = await showDialog<int>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Record physical quantity'),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Physical quantity', helperText: 'System quantity: ${number(row['system_quantity'])}')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)), child: const Text('Confirm'))],
    ));
    controller.dispose();
    if (physical == null || physical < 0) return;
    final success = await state.reviewQuantity(row['item'] as int, physical, reason: reportDifference ? 'Staff reported a stock difference' : 'Staff physical stock review');
    if (context.mounted) _notice(context, success ? 'Quantity review recorded.' : state.error ?? 'Review failed.');
  }

  Future<void> _confirmSystemStock(BuildContext context, Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Confirm stock?'),
      content: Text('Confirm the system quantity of ${number(row['system_quantity'])}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm'))],
    )) ?? false;
    if (!confirmed) return;
    final success = await state.reviewQuantity(row['item'] as int, number(row['system_quantity']), reason: 'Staff confirmed system stock');
    if (context.mounted) _notice(context, success ? 'Stock confirmed.' : state.error ?? 'Confirmation failed.');
  }
}
