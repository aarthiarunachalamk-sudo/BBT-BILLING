part of '../admin_screens.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(this.state, {super.key});
  final AdminState state;
  static const details = {
    'Grocery & Staples': ['ðŸŒ¾', '120 Products'],
    'Fruits & Vegetables': ['ðŸŽ', '85 Products'],
    'Dairy & Bakery': ['ðŸ¥›', '60 Products'],
    'Beverages': ['ðŸ¥¤', '45 Products'],
    'Snacks': ['ðŸ¿', '70 Products'],
    'Household': ['ðŸ§¼', '70 Products'],
    'Personal Care': ['ðŸ§´', '55 Products'],
  };
  Map<String, List<String>> get displayCategories => state.categories.isEmpty
      ? details
      : {
          for (final category in state.categories)
            category['name'].toString(): [
              'ðŸ“¦',
              '${category['product_count'] ?? 0} Products',
            ],
        };
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: state,
    title: 'Category Management',
    back: 4,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: SearchBox('Search categories'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: displayCategories.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final name = displayCategories.keys.elementAt(i);
              final d = displayCategories[name]!;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 3),
                leading: Text(d[0], style: const TextStyle(fontSize: 24)),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(d[1], style: const TextStyle(fontSize: 10)),
                trailing: Switch(
                  value: state.categoryActive[name]!,
                  onChanged: (v) => state.toggleCategory(name, v),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: PrimaryAction(
            'Add Category',
            icon: Icons.add,
            onPressed: () => showNotice(context, 'New category form opened'),
          ),
        ),
      ],
    ),
  );
}
