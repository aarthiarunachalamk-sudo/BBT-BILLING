part of 'user_screens.dart';

class QuantityReviewScreen extends StatelessWidget {
  const QuantityReviewScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) {
    final rows = _rowsForFilter();
    return UserShell(
      state: state,
      title: 'Quantity Review — 14 Days',
      showBack: true,
      child: Column(
        children: [
          UserFilterTabs(
            values: const ['All', 'Due', 'Updated', 'Overdue'],
            selected: state.reviewFilter,
            onSelected: state.setReviewFilter,
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyMessage('No products are due for a quantity review.')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (_, index) => _reviewCard(context, rows[index]),
                  ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _rowsForFilter() {
    final today = DateTime.now();
    final pending = state.products.where((product) {
      if (number(product['shelf_quantity']) <= 0) return false;
      final lastReview = DateTime.tryParse('${product['last_stock_review_date'] ?? ''}');
      return lastReview == null || today.difference(lastReview).inDays >= 14;
    }).map((product) {
      final lastReview = DateTime.tryParse('${product['last_stock_review_date'] ?? ''}');
      final status = lastReview != null && today.difference(lastReview).inDays > 14
          ? 'overdue'
          : 'due';
      return <String, dynamic>{
        'item': number(product['product_id']),
        'product_name': product['product_name'],
        'system_quantity': number(product['store_quantity']) + number(product['shelf_quantity']),
        'status': status,
        'is_pending_review': true,
      };
    }).toList();
    final all = [...pending, ...state.reviews];
    if (state.reviewFilter == 'All') return all;
    return all
        .where((row) => '${row['status']}'.toLowerCase() == state.reviewFilter.toLowerCase())
        .toList();
  }

  Widget _reviewCard(BuildContext context, Map<String, dynamic> row) {
    final pending = row['is_pending_review'] == true;
    final systemQuantity = number(row['system_quantity']);
    final physicalQuantity = number(row['physical_quantity']);
    final difference = physicalQuantity - systemQuantity;
    return UserCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row['product_name'] ?? 'Product #${row['item']}'}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusPill('${row['status']}'),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            pending
                ? 'System quantity: $systemQuantity • Physical count needed'
                : 'System: $systemQuantity • Physical: $physicalQuantity • Difference: $difference',
          ),
          if (pending)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Count this shelf product now to complete its 14-day review.',
                style: TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
            ),
          const SizedBox(height: 3),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton(
                onPressed: state.loading ? null : () => _recordReview(context, row),
                child: const Text('Update Quantity'),
              ),
              TextButton(
                onPressed: state.loading ? null : () => _confirmSystemStock(context, row),
                child: const Text('Confirm Stock'),
              ),
              TextButton(
                onPressed: state.loading ? null : () => _recordReview(context, row, reportDifference: true),
                child: const Text('Report Difference'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _recordReview(BuildContext context, Map<String, dynamic> row, {bool reportDifference = false}) async {
    final controller = TextEditingController();
    final physical = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record physical quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Physical quantity',
            helperText: 'System quantity: ${number(row['system_quantity'])}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text)), child: const Text('Confirm')),
        ],
      ),
    );
    controller.dispose();
    if (physical == null || physical < 0) return;
    final success = await state.reviewQuantity(
      number(row['item']),
      physical,
      reason: reportDifference ? 'Staff reported a stock difference' : 'Staff physical stock review',
    );
    if (context.mounted) _notice(context, success ? 'Quantity review recorded.' : state.error ?? 'Review failed.');
  }

  Future<void> _confirmSystemStock(BuildContext context, Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm stock?'),
            content: Text('Confirm the system quantity of ${number(row['system_quantity'])}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final success = await state.reviewQuantity(
      number(row['item']),
      number(row['system_quantity']),
      reason: 'Staff confirmed system stock',
    );
    if (context.mounted) _notice(context, success ? 'Stock confirmed.' : state.error ?? 'Confirmation failed.');
  }
}
