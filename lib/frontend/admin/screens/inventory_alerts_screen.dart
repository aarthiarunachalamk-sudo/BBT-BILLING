part of '../admin_screens.dart';

class InventoryAlertsScreen extends StatelessWidget {
  const InventoryAlertsScreen(this.state, {super.key});
  final AdminState state;
  static const rows = [
    ['Amul Butter 100g', '5', '20', '25 Jun 2025'],
    ['Britannia Bread 400g', '8', '20', '22 May 2025'],
    ['Nescafe 200g', '10', '25', '10 Jun 2025'],
    ['Surf Excel 1kg', '7', '15', '15 May 2025'],
    ['Colgate Toothpaste 100g', '4', '10', 'â€“'],
    ['Parle-G 200g', '0', '20', 'â€“'],
  ];
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Inventory Alerts',
    back: 4,
    bottom: false,
    child: Column(
      children: [
        Row(
          children: ['Low Stock', 'Expiring', 'Out of Stock']
              .map(
                (f) => Expanded(
                  child: InkWell(
                    onTap: () => state.setInventoryFilter(f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: state.inventoryFilter == f ? blue : line,
                            width: state.inventoryFilter == f ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        f,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: state.inventoryFilter == f ? blue : muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, 0),
          child: _TableHeader(['Item', 'Current', 'Min. Stock', 'Expiry']),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: rows.map((r) => _TableRow(r, highlight: true)).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Reorder Selected (3)',
                  onPressed: () =>
                      showNotice(context, 'Reorder request created'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryAction(
                  'Adjust Stock',
                  outlined: true,
                  onPressed: () =>
                      showNotice(context, 'Stock adjustment opened'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
