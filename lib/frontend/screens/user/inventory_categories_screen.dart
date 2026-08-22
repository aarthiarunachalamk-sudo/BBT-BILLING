part of 'user_screens.dart';

class InventoryCategoriesScreen extends StatefulWidget {
  const InventoryCategoriesScreen(this.state, {super.key});
  final UserState state;

  @override
  State<InventoryCategoriesScreen> createState() => _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState extends State<InventoryCategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.categories.where((category) =>
      '${category['name']}'.toLowerCase().contains(_query.toLowerCase().trim())).toList();
    return UserShell(
      state: widget.state,
      title: 'Inventory',
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search category...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        if (widget.state.canManageInventory)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.state.go(UserPage.addProduct),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Product'),
              ),
            ),
          ),
        Expanded(
          child: categories.isEmpty
              ? EmptyMessage(widget.state.categories.isEmpty
                  ? 'No active categories were returned by the server.'
                  : 'No category matches your search.')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: .92,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (_, index) {
                    final category = categories[index];
                    final name = '${category['name']}';
                    return _CategoryTile(
                      name: name,
                      imagePath: _categoryImage(name),
                      onTap: () => widget.state.openCategory(category),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  String _categoryImage(String name) {
    final value = name.toLowerCase();
    if (value.contains('dairy') || value.contains('milk')) return 'assets/category_icons/dairy.png';
    if (value.contains('beverage') || value.contains('drink') || value.contains('juice')) return 'assets/category_icons/beverages.png';
    if (value.contains('snack') || value.contains('chip') || value.contains('biscuit')) return 'assets/category_icons/snacks.png';
    if (value.contains('personal') || value.contains('beauty') || value.contains('care')) return 'assets/category_icons/personal_care.png';
    if (value.contains('house') || value.contains('clean') || value.contains('laundry')) return 'assets/category_icons/household.png';
    if (value.contains('frozen') || value.contains('ice')) return 'assets/category_icons/frozen_foods.png';
    if (value.contains('bakery') || value.contains('bread') || value.contains('cake')) return 'assets/category_icons/bakery.png';
    return 'assets/category_icons/grocery.png';
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.imagePath, required this.onTap});
  final String name;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: const BorderSide(color: Color(0xFFDCE3EC)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 7),
        child: Column(children: [
          Expanded(child: Image.asset(imagePath, fit: BoxFit.contain, filterQuality: FilterQuality.medium)),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    ),
  );
}
