part of 'user_screens.dart';

class StockMovementScreen extends StatelessWidget {
  const StockMovementScreen(this.state, {super.key});
  final UserState state;

  @override
  Widget build(BuildContext context) => UserShell(
    state: state,
    title: 'Stock Movement History',
    showBack: true,
    backPage: UserPage.currentStock,
    child: Column(children: [
      UserFilterTabs(values: const ['Today', 'Week', 'Month', 'Year', 'Custom'], selected: state.movementPeriod, onSelected: (period) async {
        if (period != 'Custom') { state.setMovementPeriod(period); return; }
        final today = DateTime.now();
        final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: today, initialDateRange: state.movementStartDate == null || state.movementEndDate == null ? null : DateTimeRange(start: state.movementStartDate!, end: state.movementEndDate!));
        if (range != null) state.setMovementDateRange(range.start, range.end);
      }),
      if (state.movementPeriod == 'Custom' && state.movementStartDate != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('${_date(state.movementStartDate!)} – ${_date(state.movementEndDate!)}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ),
      Expanded(
        child: state.stockMovements.isEmpty
            ? const EmptyMessage('No stock movements found for this period.')
            : RefreshIndicator(
                onRefresh: state.refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                  itemCount: state.stockMovements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (_, index) => _movementCard(state.stockMovements[index]),
                ),
              ),
      ),
    ]),
  );

  Widget _movementCard(Map<String, dynamic> movement) {
    final quantity = number(movement['quantity']);
    final type = '${movement['movement_type'] ?? 'STOCK_MOVEMENT'}';
    final source = '${movement['source_location'] ?? '-'}';
    final destination = '${movement['destination_location'] ?? '-'}';
    final created = movement['created_at']?.toString() ?? '';
    return UserCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        CircleAvatar(backgroundColor: userBlue.withValues(alpha: .12), child: const Icon(Icons.swap_horiz_rounded, color: userBlue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${movement['product_name'] ?? 'Product'}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text('$source → $destination  •  $type'.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
          const SizedBox(height: 3),
          Text(_dateTime(created), style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$quantity units', style: const TextStyle(fontWeight: FontWeight.w900, color: userGreen)),
          Text('Store: ${number(movement['store_before'])} → ${number(movement['store_after'])}', style: const TextStyle(fontSize: 10)),
          Text('Shelf: ${number(movement['shelf_before'])} → ${number(movement['shelf_after'])}', style: const TextStyle(fontSize: 10)),
        ]),
      ]),
    );
  }

  static String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _dateTime(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();
    return parsed == null ? '-' : '${_date(parsed)} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
}
