part of 'user_screens.dart';

class InventoryCategoriesScreen extends StatefulWidget {
  const InventoryCategoriesScreen(this.state, {super.key});
  final UserState state;

  @override
  State<InventoryCategoriesScreen> createState() =>
      _InventoryCategoriesScreenState();
}

class _InventoryCategoriesScreenState extends State<InventoryCategoriesScreen> {
  String _query = '';
  String? _selectedRack;

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase().trim();
    final filteredProducts = widget.state.products.where((product) {
      final searchable = [
        product['product_name'],
        product['name'],
        product['product_id'],
        product['sku'],
        product['barcode'],
        product['rack_name'],
        product['rack_location'],
        product['store_section'],
        product['category_name'],
        product['location_label'],
      ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
      return searchable.contains(query);
    }).toList();
    final groups = _groupUserProducts(filteredProducts);
    final selectedRack =
        query.isEmpty && groups.any((group) => group.name == _selectedRack)
        ? _selectedRack
        : null;
    final visibleGroups = selectedRack == null
        ? groups
        : groups.where((group) => group.name == selectedRack).toList();

    return UserShell(
      state: widget.state,
      title: 'Products',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              onChanged: (value) => setState(() {
                _query = value;
                if (value.trim().isNotEmpty) _selectedRack = null;
              }),
              decoration: InputDecoration(
                hintText: 'Search product, rack or category',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => setState(() => _query = ''),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (widget.state.canManageInventory)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.state.go(UserPage.addProduct),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Product'),
                ),
              ),
            ),
          if (groups.length > 1)
            _UserRackSelector(
              groups: groups,
              selectedRack: selectedRack,
              onSelected: (rack) => setState(() => _selectedRack = rack),
            ),
          Expanded(
            child: visibleGroups.isEmpty
                ? EmptyMessage(
                    widget.state.products.isEmpty
                        ? 'No products were returned by the server.'
                        : 'No product, rack or category matches your search.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                    itemCount: visibleGroups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _UserCatalogSummary(
                          locations: groups.length,
                          categories: groups.fold(
                            0,
                            (total, group) => total + group.categories.length,
                          ),
                          products: filteredProducts.length,
                        );
                      }
                      return _UserRackSection(
                        group: visibleGroups[index - 1],
                        expanded: query.isNotEmpty || visibleGroups.length == 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserRackSelector extends StatelessWidget {
  const _UserRackSelector({
    required this.groups,
    required this.selectedRack,
    required this.onSelected,
  });

  final List<_UserRackGroup> groups;
  final String? selectedRack;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.near_me_outlined, color: userBlue, size: 15),
              SizedBox(width: 6),
              Text(
                'Jump to location',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _UserRackChip(
                label: 'All',
                count: groups.length,
                selected: selectedRack == null,
                icon: Icons.grid_view_rounded,
                onTap: () => onSelected(null),
              ),
              for (final group in groups)
                _UserRackChip(
                  label: group.name,
                  count: group.productCount,
                  selected: selectedRack == group.name,
                  icon: _userRackIcon(group.name),
                  onTap: () => onSelected(group.name),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UserRackChip extends StatelessWidget {
  const _UserRackChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: Material(
      color: selected ? userBlue : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? userBlue : const Color(0xFFDCE3EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : Colors.blueGrey,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : userNavy,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .18)
                      : const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.blueGrey,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _UserCatalogSummary extends StatelessWidget {
  const _UserCatalogSummary({
    required this.locations,
    required this.categories,
    required this.products,
  });

  final int locations;
  final int categories;
  final int products;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [userNavy, Color(0xFF17549D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: userNavy.withValues(alpha: .16),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        const Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Store catalogue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Find every product faster',
                style: TextStyle(color: Color(0xFFDCEBFF), fontSize: 9),
              ),
            ],
          ),
        ),
        _UserSummaryMetric(value: '$locations', label: 'Locations'),
        _UserSummaryMetric(value: '$categories', label: 'Categories'),
        _UserSummaryMetric(value: '$products', label: 'Products'),
      ],
    ),
  );
}

class _UserSummaryMetric extends StatelessWidget {
  const _UserSummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFBCD7FA), fontSize: 7),
          ),
        ),
      ],
    ),
  );
}

class _UserRackSection extends StatelessWidget {
  const _UserRackSection({required this.group, required this.expanded});

  final _UserRackGroup group;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final coldStorage = _isUserColdStorage(group.name);
    final accent = coldStorage ? const Color(0xFF0891B2) : userBlue;
    return Card(
      key: PageStorageKey('user-rack-${group.name}-$expanded'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDCE3EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: expanded,
        maintainState: true,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        iconColor: accent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_userRackIcon(group.name), color: accent, size: 22),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${group.categories.length} categories  •  ${group.productCount} products',
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
        ),
        children: group.categories
            .map(
              (category) => _UserCategorySection(
                rackName: group.name,
                category: category,
                expanded: expanded || group.categories.length == 1,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _UserCategorySection extends StatelessWidget {
  const _UserCategorySection({
    required this.rackName,
    required this.category,
    required this.expanded,
  });

  final String rackName;
  final _UserCategoryGroup category;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Material(
      color: const Color(0xFFF8FAFD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(
          'user-rack-$rackName-category-${category.name}-$expanded',
        ),
        initiallyExpanded: expanded,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: userBlue.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.category_outlined, color: userBlue, size: 17),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${category.products.length} item${category.products.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
        ),
        children: [
          for (var index = 0; index < category.products.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _UserProductRow(product: category.products[index]),
          ],
        ],
      ),
    ),
  );
}

class _UserProductRow extends StatelessWidget {
  const _UserProductRow({required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final quantity = number(product['store_quantity']);
    final minimum = number(product['minimum_quantity']);
    final savedBarcode = product['barcode']?.toString().trim() ?? '';
    final barcode = savedBarcode.isNotEmpty
        ? savedBarcode
        : product['sku']?.toString().trim() ?? '';
    final status = quantity == 0
        ? 'Out of Stock'
        : quantity <= minimum
        ? 'Low Stock'
        : 'In Stock';
    return ListTile(
      minTileHeight: 82,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      leading: ProductImageWidget(
        imageUrl: product['image_url'] ?? product['product_image_url'],
        width: 52,
        height: 52,
      ),
      title: Text(
        '${product['product_name'] ?? product['name'] ?? 'Product'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (barcode.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 13,
                    color: userBlue,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Barcode: $barcode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.blueGrey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
            ],
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                _UserStockChip(
                  label: 'Store',
                  value: quantity,
                  color: userBlue,
                ),
                _UserStockChip(
                  label: 'Minimum',
                  value: minimum,
                  color: userOrange,
                ),
              ],
            ),
          ],
        ),
      ),
      trailing: StatusPill(status),
    );
  }
}

class _UserStockChip extends StatelessWidget {
  const _UserStockChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: .16)),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800),
    ),
  );
}

class _UserRackGroup {
  const _UserRackGroup({required this.name, required this.categories});

  final String name;
  final List<_UserCategoryGroup> categories;

  int get productCount =>
      categories.fold(0, (total, category) => total + category.products.length);
}

class _UserCategoryGroup {
  const _UserCategoryGroup({required this.name, required this.products});

  final String name;
  final List<Map<String, dynamic>> products;
}

List<_UserRackGroup> _groupUserProducts(List<Map<String, dynamic>> products) {
  final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};
  for (final product in products) {
    final rack = _firstUserProductLabel(product, const [
      'rack_name',
      'rack_location',
      'store_section',
    ], fallback: 'Unassigned');
    final category = _firstUserProductLabel(product, const [
      'category_name',
    ], fallback: 'Uncategorized');
    grouped
        .putIfAbsent(rack, () => {})
        .putIfAbsent(category, () => [])
        .add(product);
  }

  final racks = grouped.entries.map((rack) {
    final categories =
        rack.value.entries.map((category) {
          category.value.sort(
            (a, b) => '${a['product_name'] ?? a['name'] ?? ''}'
                .toLowerCase()
                .compareTo(
                  '${b['product_name'] ?? b['name'] ?? ''}'.toLowerCase(),
                ),
          );
          return _UserCategoryGroup(
            name: category.key,
            products: category.value,
          );
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return _UserRackGroup(name: rack.key, categories: categories);
  }).toList();
  racks.sort((a, b) {
    if (a.name == 'Unassigned') return 1;
    if (b.name == 'Unassigned') return -1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return racks;
}

String _firstUserProductLabel(
  Map<String, dynamic> product,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = product[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

bool _isUserColdStorage(String name) {
  final normalized = name.toLowerCase();
  return normalized.contains('fridge') ||
      normalized.contains('freezer') ||
      normalized.contains('cold');
}

IconData _userRackIcon(String name) {
  if (_isUserColdStorage(name)) return Icons.kitchen_outlined;
  if (name.toLowerCase() == 'unassigned') return Icons.help_outline_rounded;
  return Icons.shelves;
}
