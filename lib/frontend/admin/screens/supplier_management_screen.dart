part of '../admin_screens.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen(this.state, {super.key});
  final AdminState state;
  static const suppliers = [
    ['Balaji Distributors', '27AACCB1234F1Z5', '9876543210', 'â‚¹ 24,500.00'],
    ['Shree Traders', '07CCAZQ0002G2Z1', '9911122233', 'â‚¹ 18,750.00'],
    ['Fresh Foods Pvt. Ltd.', '01AABCPQ4567H1Z2', '9877754456', 'â‚¹ 9,350.00'],
    ['Quality Supplies', '19BBRTY9001F2Z3', '9355066670', 'â‚¹ 5,120.00'],
  ];
  List<List<String>> get displaySuppliers => state.suppliers.isEmpty
      ? suppliers
      : state.suppliers
            .map(
              (s) => <String>[
                s['name'].toString(),
                s['gstin']?.toString() ?? '',
                s['phone']?.toString() ?? '',
                'â‚¹ 0.00',
              ],
            )
            .toList();
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Supplier Management',
    back: 4,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: SearchBox('Search suppliers'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displaySuppliers.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final s = displaySuppliers[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEAF2FF),
                  child: Icon(
                    i.isEven ? Icons.apartment : Icons.storefront,
                    color: blue,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s[0],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      'Active',
                      style: TextStyle(fontSize: 9, color: green),
                    ),
                  ],
                ),
                subtitle: Text(
                  'GSTIN: ${s[1]}\nPhone: ${s[2]}\nOutstanding: ${s[3]}',
                  style: const TextStyle(fontSize: 9, height: 1.5),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: PrimaryAction(
                  'Add Supplier',
                  icon: Icons.add,
                  onPressed: () =>
                      showNotice(context, 'New supplier form opened'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: PrimaryAction(
                  'View Ledger',
                  outlined: true,
                  onPressed: () => state.go(8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
