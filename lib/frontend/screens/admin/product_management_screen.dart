part of 'admin_screens.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> _categoryTabs = [];
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _categoryTabs = ['All'];
    for (final c in widget.state.categories) {
      final name = c['name']?.toString() ?? '';
      if (name.isNotEmpty) _categoryTabs.add(name);
    }
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
    unawaited(_loadProductsOnEntry());
  }

  Future<void> _loadProductsOnEntry() async {
    if (widget.state.products.isNotEmpty || _loadingProducts) return;
    setState(() => _loadingProducts = true);
    // Do not hold the product page until every unrelated admin endpoint has
    // refreshed. Once the catalogue arrives, the user can start working.
    while (mounted &&
        widget.state.refreshing &&
        widget.state.products.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    if (widget.state.products.isEmpty) {
      await widget.state.refreshProducts();
    }
    if (!mounted) return;
    _buildTabs();
    setState(() => _loadingProducts = false);
  }

  @override
  void didUpdateWidget(covariant ProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildTabs();
  }

  void _buildTabs() {
    final cats = <String>['All'];
    for (final c in widget.state.categories) {
      final name = c['name']?.toString() ?? '';
      if (name.isNotEmpty) cats.add(name);
    }
    if (_categoryTabs.length != cats.length ||
        !_categoryTabs.every((t) => cats.contains(t))) {
      _tabController.dispose();
      _categoryTabs = cats;
      _tabController = TabController(length: cats.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // Some Android devices report a wide logical width in portrait. Treat
    // those as mobile too; the desktop header cannot fit their short height.
    final mediaSize = MediaQuery.sizeOf(context);
    final mobile = mediaSize.width < 900 || mediaSize.height < 700;
    final waitingForProducts =
        state.products.isEmpty && (_loadingProducts || state.refreshing);
    final query = state.productQuery.trim().toLowerCase();

    final allProducts = state.products.where((product) {
      final searchable = [
        product['name'],
        product['sku'],
        product['barcode'],
        product['brand_name'],
        product['category_name'],
        product['rack_name'],
        product['store_section'],
        product['rack_location'],
      ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');
      final status = product['stock_status']?.toString();
      final matchesStock = switch (state.productStockFilter) {
        'In Stock' => status == 'in_stock',
        'Low Stock' => status == 'low_stock',
        'Out of Stock' => status == 'out_of_stock',
        _ => true,
      };
      return searchable.contains(query) && matchesStock;
    }).toList();

    final lowStockCount = state.products
        .where((p) => p['stock_status'] == 'low_stock')
        .length;
    final outOfStockCount = state.products
        .where((p) => p['stock_status'] == 'out_of_stock')
        .length;
    final inventoryValue = state.products.fold<double>(0, (sum, p) {
      final cost = double.tryParse(p['purchase_price']?.toString() ?? '') ?? 0;
      final stock = int.tryParse(p['stock_quantity']?.toString() ?? '') ?? 0;
      return sum + cost * stock;
    });

    return _AdminPage(
      state: state,
      title: 'Product Management',
      back: 1,
      actions: [
        PopupMenuButton<int>(
          tooltip: 'Catalog tools',
          onSelected: state.go,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 6, child: Text('Categories')),
            PopupMenuItem(value: 7, child: Text('Suppliers')),
            PopupMenuItem(value: 9, child: Text('Inventory alerts')),
          ],
        ),
      ],
      child: waitingForProducts
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Loading products...', style: TextStyle(color: muted)),
                ],
              ),
            )
          : mobile
          ? _MobileProductList(state: state, products: allProducts)
          : Column(
              children: [
                // ── Stats + search ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: _CatalogHeader(
                    totalProducts: state.products.length,
                    lowStockCount: lowStockCount,
                    outOfStockCount: outOfStockCount,
                    inventoryValue: inventoryValue,
                    onAddProduct: () => state.go(5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBox(
                          'Search by name, SKU or category',
                          trailing: Icons.tune_rounded,
                          onTrailingTap: () =>
                              _showProductFilters(context, state),
                          onChanged: state.setProductQuery,
                        ),
                      ),
                      if (state.productStockFilter != 'All') ...[
                        const SizedBox(width: 10),
                        InputChip(
                          avatar: const Icon(Icons.filter_alt, size: 16),
                          label: Text(state.productStockFilter),
                          onDeleted: () => state.setProductStockFilter('All'),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Category tabs ────────────────────────────────────────────────
                if (_categoryTabs.length > 1)
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    tabs: _categoryTabs.map((t) => Tab(text: t)).toList(),
                  ),

                // ── Product grid per tab ─────────────────────────────────────────
                Expanded(
                  child: _categoryTabs.length > 1
                      ? TabBarView(
                          controller: _tabController,
                          children: _categoryTabs.map((tab) {
                            final products = tab == 'All'
                                ? allProducts
                                : allProducts
                                      .where(
                                        (p) =>
                                            p['category_name']
                                                ?.toString()
                                                .toLowerCase() ==
                                            tab.toLowerCase(),
                                      )
                                      .toList();
                            return _ProductGrid(
                              state: state,
                              products: products,
                              categoryName: tab == 'All' ? null : tab,
                            );
                          }).toList(),
                        )
                      : _ProductGrid(state: state, products: allProducts),
                ),
              ],
            ),
    );
  }
}

class _MobileProductList extends StatefulWidget {
  const _MobileProductList({required this.state, required this.products});

  final AdminState state;
  final List<Map<String, dynamic>> products;

  @override
  State<_MobileProductList> createState() => _MobileProductListState();
}

class _MobileProductListState extends State<_MobileProductList> {
  String? _selectedRack;

  AdminState get state => widget.state;
  List<Map<String, dynamic>> get products => widget.products;

  @override
  Widget build(BuildContext context) {
    final groups = _groupProductsByRack(products);
    final searching = state.productQuery.trim().isNotEmpty;
    final selectedRack =
        !searching && groups.any((group) => group.name == _selectedRack)
        ? _selectedRack
        : null;
    final visibleGroups = selectedRack == null
        ? groups
        : groups.where((group) => group.name == selectedRack).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: SearchBox(
            'Search product, rack or category',
            trailing: Icons.filter_alt_outlined,
            onTrailingTap: () => _showProductFilters(context, state),
            onChanged: (value) {
              if (value.trim().isNotEmpty && _selectedRack != null) {
                setState(() => _selectedRack = null);
              }
              state.setProductQuery(value);
            },
          ),
        ),
        if (state.productStockFilter != 'All')
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                avatar: const Icon(Icons.filter_alt, size: 16),
                label: Text(state.productStockFilter),
                onDeleted: () => state.setProductStockFilter('All'),
              ),
            ),
          ),
        if (groups.length > 1)
          _RackQuickSelector(
            groups: groups,
            selectedRack: selectedRack,
            onSelected: (rack) => setState(() => _selectedRack = rack),
          ),
        Expanded(
          child: visibleGroups.isEmpty
              ? const _EmptyState(
                  'No products found.',
                  icon: Icons.inventory_2_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  itemCount: visibleGroups.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CatalogOverviewBar(
                        racks: groups.length,
                        categories: groups.fold(
                          0,
                          (total, group) => total + group.categories.length,
                        ),
                        products: products.length,
                      );
                    }
                    return _RackProductSection(
                      state: state,
                      group: visibleGroups[index - 1],
                      initiallyExpanded: searching || visibleGroups.length == 1,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: PrimaryAction(
            'Add Product',
            icon: Icons.add,
            onPressed: () => state.go(5),
          ),
        ),
      ],
    );
  }
}

class _RackQuickSelector extends StatelessWidget {
  const _RackQuickSelector({
    required this.groups,
    required this.selectedRack,
    required this.onSelected,
  });

  final List<_RackProductGroup> groups;
  final String? selectedRack;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.near_me_outlined, size: 15, color: blue),
              SizedBox(width: 6),
              Text(
                'Jump to location',
                style: TextStyle(
                  color: ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _RackChoiceChip(
                label: 'All',
                count: groups.length,
                selected: selectedRack == null,
                imageAsset: 'assets/location_icons/general.png',
                onTap: () => onSelected(null),
              ),
              for (final group in groups)
                _RackChoiceChip(
                  label: group.name,
                  count: group.productCount,
                  selected: selectedRack == group.name,
                  imageAsset: _locationImageAsset(group.name),
                  onTap: () => onSelected(group.name),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RackChoiceChip extends StatelessWidget {
  const _RackChoiceChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.imageAsset,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: Material(
      color: selected ? blue : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? blue : line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 11, 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .94)
                      : const Color(0xFFF0F6FF),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(imageAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : ink,
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
                    color: selected ? Colors.white : muted,
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

String _locationImageAsset(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('fridge') ||
      normalized.contains('freezer') ||
      normalized.contains('cold')) {
    return 'assets/location_icons/fridge.png';
  }
  if (normalized.contains('general') || normalized == 'unassigned') {
    return 'assets/location_icons/general.png';
  }
  return 'assets/location_icons/rack.png';
}

class _CatalogOverviewBar extends StatelessWidget {
  const _CatalogOverviewBar({
    required this.racks,
    required this.categories,
    required this.products,
  });

  final int racks;
  final int categories;
  final int products;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [navy, Color(0xFF0B5EC4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: navy.withValues(alpha: .16),
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
                'Browse by location and category',
                style: TextStyle(color: Color(0xFFD9E9FF), fontSize: 9),
              ),
            ],
          ),
        ),
        _OverviewMetric(value: '$racks', label: 'Locations'),
        _OverviewMetric(value: '$categories', label: 'Categories'),
        _OverviewMetric(value: '$products', label: 'Products'),
      ],
    ),
  );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(left: 4),
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
    ),
  );
}

class _RackProductSection extends StatelessWidget {
  const _RackProductSection({
    required this.state,
    required this.group,
    required this.initiallyExpanded,
  });

  final AdminState state;
  final _RackProductGroup group;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final isColdStorage =
        group.name.toLowerCase().contains('fridge') ||
        group.name.toLowerCase().contains('freezer') ||
        group.name.toLowerCase().contains('cold');
    final isGeneral =
        group.name.toLowerCase().contains('general') ||
        group.name.toLowerCase() == 'unassigned';
    final accent = isColdStorage
        ? const Color(0xFF00A6C8)
        : isGeneral
        ? const Color(0xFF6D4FD3)
        : blue;

    return Card(
      key: PageStorageKey('rack-${group.name}-$initiallyExpanded'),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        iconColor: accent,
        collapsedIconColor: muted,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        leading: Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, accent.withValues(alpha: .10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: .18)),
          ),
          child: Image.asset(
            _locationImageAsset(group.name),
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${group.categories.length} categories  •  ${group.productCount} products',
          style: const TextStyle(fontSize: 10, color: muted),
        ),
        children: group.categories
            .map(
              (category) => _CategoryProductSection(
                state: state,
                rackName: group.name,
                category: category,
                initiallyExpanded:
                    initiallyExpanded || group.categories.length == 1,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CategoryProductSection extends StatelessWidget {
  const _CategoryProductSection({
    required this.state,
    required this.rackName,
    required this.category,
    required this.initiallyExpanded,
  });

  final AdminState state;
  final String rackName;
  final _CategoryProductGroup category;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F2)),
      ),
      child: ExpansionTile(
        key: PageStorageKey(
          'rack-$rackName-category-${category.name}-$initiallyExpanded',
        ),
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
        leading: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDEBFF)),
          ),
          child: Image.asset(
            _categoryImageAsset(category.name),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.inventory_2_outlined, color: blue, size: 20),
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${category.products.length} item${category.products.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 9, color: muted),
        ),
        children: [
          for (var index = 0; index < category.products.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _MobileProductRow(state: state, product: category.products[index]),
          ],
        ],
      ),
    ),
  );
}

String _categoryImageAsset(String categoryName) {
  final normalized = categoryName.toLowerCase().replaceAll(
    RegExp(r'[^a-z]'),
    '',
  );
  if (normalized.contains('beverage') ||
      normalized.contains('drink') ||
      normalized.contains('juice')) {
    return 'assets/category_icons/beverages.png';
  }
  if (normalized.contains('dairy') || normalized.contains('milk')) {
    return 'assets/category_icons/dairy.png';
  }
  if (normalized.contains('bakery') || normalized.contains('bread')) {
    return 'assets/category_icons/bakery.png';
  }
  if (normalized.contains('frozen') || normalized.contains('icecream')) {
    return 'assets/category_icons/frozen_foods.png';
  }
  if (normalized.contains('household') || normalized.contains('cleaning')) {
    return 'assets/category_icons/household.png';
  }
  if (normalized.contains('personalcare') ||
      normalized.contains('cosmetic') ||
      normalized.contains('hygiene')) {
    return 'assets/category_icons/personal_care.png';
  }
  if (normalized.contains('snack') ||
      normalized.contains('biscuit') ||
      normalized.contains('confection')) {
    return 'assets/category_icons/snacks.png';
  }
  return 'assets/category_icons/grocery.png';
}

class _MobileProductRow extends StatelessWidget {
  const _MobileProductRow({required this.state, required this.product});

  final AdminState state;
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final status = product['stock_status']?.toString() ?? '';
    final brand = product['brand_name']?.toString().trim() ?? '';
    final store = product['store_stock'] ?? 0;
    final shelf = product['shelf_stock'] ?? 0;
    final total = product['total_stock'] ?? product['stock_quantity'] ?? 0;
    final price = double.tryParse('${product['selling_price'] ?? ''}');
    return ListTile(
      minTileHeight: 92,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      onTap: () => _showEditPriceSheet(context, state, product),
      leading: InkWell(
        onTap: () => _replaceProductImage(context, state, product),
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: line),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _ProductImage(
                  url: _productImageUrl(state, product['image']),
                ),
              ),
            ),
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        product['name']?.toString() ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${brand.isEmpty ? '' : '$brand • '}SKU: ${product['sku'] ?? '—'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: muted),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _MiniStock(label: 'Store', value: '$store'),
                _MiniStock(label: 'Shelf', value: '$shelf'),
                _MiniStock(label: 'Total', value: '$total', emphasized: true),
              ],
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StockBadge(status: status),
          if (price != null) ...[
            const SizedBox(height: 7),
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStock extends StatelessWidget {
  const _MiniStock({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: emphasized ? blue.withValues(alpha: .09) : Colors.white,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: emphasized ? blue.withValues(alpha: .22) : line,
      ),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(
        color: emphasized ? blue : muted,
        fontSize: 7.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _RackProductGroup {
  const _RackProductGroup({required this.name, required this.categories});

  final String name;
  final List<_CategoryProductGroup> categories;

  int get productCount =>
      categories.fold(0, (total, category) => total + category.products.length);
}

class _CategoryProductGroup {
  const _CategoryProductGroup({required this.name, required this.products});

  final String name;
  final List<Map<String, dynamic>> products;
}

List<_RackProductGroup> _groupProductsByRack(
  List<Map<String, dynamic>> products,
) {
  final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};
  for (final product in products) {
    final rack = _firstProductLabel(product, const [
      'rack_name',
      'rack_location',
      'store_section',
    ], fallback: 'Unassigned');
    final category = _firstProductLabel(product, const [
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
            (a, b) => '${a['name'] ?? ''}'.toLowerCase().compareTo(
              '${b['name'] ?? ''}'.toLowerCase(),
            ),
          );
          return _CategoryProductGroup(
            name: category.key,
            products: category.value,
          );
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return _RackProductGroup(name: rack.key, categories: categories);
  }).toList();
  racks.sort((a, b) {
    if (a.name == 'Unassigned') return 1;
    if (b.name == 'Unassigned') return -1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return racks;
}

String _firstProductLabel(
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

/// A scrollable grid of product cards, with an empty state and an
/// "Add Product" FAB when a [categoryName] is specified.
class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.state,
    required this.products,
    this.categoryName,
  });

  final AdminState state;
  final List<Map<String, dynamic>> products;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _EmptyState(
        categoryName != null
            ? 'No products in $categoryName yet.\nTap + to add one.'
            : state.products.isEmpty
            ? 'No products yet. Add your first product.'
            : 'No products match the selected filters.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1060
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 238,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCatalogCard(
              state: state,
              product: product,
              onImageTap: () => _replaceProductImage(context, state, product),
            );
          },
        );
      },
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.inventoryValue,
    required this.onAddProduct,
  });

  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
  final double inventoryValue;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product catalog',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage pricing, availability, images and catalog health.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (constraints.maxWidth >= 620) ...[
              const SizedBox(width: 20),
              SizedBox(
                width: 170,
                child: PrimaryAction(
                  'Add Product',
                  icon: Icons.add_rounded,
                  onPressed: onAddProduct,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _CatalogStat(
              icon: Icons.inventory_2_outlined,
              label: 'Active catalog',
              value: '$totalProducts products',
              color: blue,
            ),
            _CatalogStat(
              icon: Icons.warning_amber_rounded,
              label: 'Low stock',
              value: '$lowStockCount products',
              color: Colors.orange,
            ),
            _CatalogStat(
              icon: Icons.remove_shopping_cart_outlined,
              label: 'Out of stock',
              value: '$outOfStockCount products',
              color: red,
            ),
            _CatalogStat(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Inventory cost',
              value: _money(inventoryValue),
              color: green,
            ),
          ];
          final columns = constraints.maxWidth >= 880 ? 4 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 86,
            children: cards,
          );
        },
      ),
      if (MediaQuery.sizeOf(context).width < 620) ...[
        const SizedBox(height: 12),
        PrimaryAction(
          'Add Product',
          icon: Icons.add_rounded,
          onPressed: onAddProduct,
        ),
      ],
    ],
  );
}

class _CatalogStat extends StatelessWidget {
  const _CatalogStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: muted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProductCatalogCard extends StatelessWidget {
  const _ProductCatalogCard({
    required this.state,
    required this.product,
    required this.onImageTap,
  });

  final AdminState state;
  final Map<String, dynamic> product;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    final status = product['stock_status']?.toString() ?? '';
    final mrp = double.tryParse(product['mrp']?.toString() ?? '');
    final selling =
        double.tryParse(product['selling_price']?.toString() ?? '') ?? 0;
    final discount = mrp == null || mrp <= 0 || selling >= mrp
        ? null
        : ((mrp - selling) * 100 / mrp).round();
    final verified = product['price_verified_at'] != null;

    return SectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditPriceSheet(context, state, product),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Add or replace product image',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onImageTap,
                      child: SizedBox.square(
                        dimension: 76,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _ProductImage(
                                url: _productImageUrl(state, product['image']),
                              ),
                            ),
                            const Positioned(
                              right: 4,
                              bottom: 4,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: blue,
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product['brand_name']?.toString().isNotEmpty == true ? '${product['brand_name']} • ' : ''}${product['category_name']?.toString() ?? 'Uncategorized'}'
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['name']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product['sku']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if ('${product['store_section'] ?? ''}${product['rack_location'] ?? ''}'
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: blue,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  [
                                        product['store_section'],
                                        product['rack_location'],
                                      ]
                                      .where(
                                        (value) =>
                                            value != null &&
                                            value.toString().trim().isNotEmpty,
                                      )
                                      .join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: blue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(selling),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (mrp != null) ...[
                    const SizedBox(width: 7),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        _money(mrp),
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                  if (discount != null) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F7EF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: const TextStyle(
                          color: green,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 11),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StockBadge(status: status),
                  const SizedBox(width: 8),
                  Text(
                    'Store: ${product['store_stock'] ?? product['stock_quantity'] ?? 0}',
                    style: const TextStyle(fontSize: 9, color: muted),
                  ),
                  const Spacer(),
                  if (verified)
                    Tooltip(
                      message:
                          'Price verified ${_dateText(product['price_verified_at'])}',
                      child: const Icon(
                        Icons.verified_outlined,
                        size: 17,
                        color: green,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    'GST ${product['tax_percent'] ?? 0}%',
                    style: const TextStyle(fontSize: 9, color: muted),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: muted.withValues(alpha: .6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      'out_of_stock' => (red, const Color(0xFFFFECEE)),
      'low_stock' => (Colors.orange, const Color(0xFFFFF4DF)),
      _ => (green, const Color(0xFFE7F7EF)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _productImageUrl(AdminState state, dynamic rawValue) {
  final value = rawValue?.toString() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final origin = state.api.baseUrl.replaceFirst(RegExp(r'/api$'), '');
  return '$origin${value.startsWith('/') ? '' : '/'}$value';
}

Future<void> _replaceProductImage(
  BuildContext context,
  AdminState state,
  Map<String, dynamic> product,
) async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (image == null) return;
  try {
    await state.updateProductImage(
      product['id'] as int,
      await image.readAsBytes(),
      image.name,
    );
    if (context.mounted) showNotice(context, 'Product image updated');
  } catch (error) {
    if (context.mounted) showNotice(context, error.toString());
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const ColoredBox(
        color: page,
        child: Icon(Icons.inventory_2_outlined, color: blue),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: page,
        child: Icon(Icons.broken_image_outlined, color: muted),
      ),
    );
  }
}

bool _sameCalendarDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

Future<void> _showEditPriceSheet(
  BuildContext context,
  AdminState state,
  Map<String, dynamic> product,
) async {
  final result = await showModalBottomSheet<_PriceSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) =>
        _EditProductPriceSheet(state: state, product: product),
  );
  if (!context.mounted) return;
  switch (result) {
    case _PriceSheetResult.updated:
      showNotice(context, 'Prices updated — open quotations recalculated.');
    case _PriceSheetResult.deleted:
      showNotice(context, 'Product deleted.');
    case null:
      return;
  }
}

enum _PriceSheetResult { updated, deleted }

class _EditProductPriceSheet extends StatefulWidget {
  const _EditProductPriceSheet({required this.state, required this.product});

  final AdminState state;
  final Map<String, dynamic> product;

  @override
  State<_EditProductPriceSheet> createState() => _EditProductPriceSheetState();
}

class _EditProductPriceSheetState extends State<_EditProductPriceSheet> {
  static const slabs = [0, 5, 12, 18, 28];

  late final TextEditingController sellingCtrl;
  late final TextEditingController purchaseCtrl;
  late final TextEditingController mrpCtrl;
  late DateTime effectiveDate;
  late int gst;
  bool saving = false;
  String? errorText;

  int get productId => widget.product['id'] as int;

  @override
  void initState() {
    super.initState();
    sellingCtrl = TextEditingController(
      text: widget.product['selling_price']?.toString() ?? '',
    );
    purchaseCtrl = TextEditingController(
      text: widget.product['purchase_price']?.toString() ?? '',
    );
    mrpCtrl = TextEditingController(
      text: widget.product['mrp']?.toString() ?? '',
    );
    effectiveDate = DateTime.now();
    gst =
        int.tryParse(
          double.tryParse(
                widget.product['tax_percent']?.toString() ?? '',
              )?.toStringAsFixed(0) ??
              '0',
        ) ??
        0;
    if (!slabs.contains(gst)) gst = 18;
  }

  @override
  void dispose() {
    sellingCtrl.dispose();
    purchaseCtrl.dispose();
    mrpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      top: 4,
      bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_outlined, color: blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.product['name']?.toString() ?? 'Edit Prices',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose Today or Tomorrow. Saving the same date again edits that schedule; old bills stay unchanged.',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sellingCtrl,
                    enabled: !saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Selling Price (₹) *',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: purchaseCtrl,
                    enabled: !saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Purchase Price (₹)',
                      prefixText: '₹ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.today_outlined, size: 16),
                  label: const Text('Today'),
                  selected: _sameCalendarDay(effectiveDate, DateTime.now()),
                  onSelected: saving ? null : (_) => _selectToday(),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.next_plan_outlined, size: 16),
                  label: const Text('Tomorrow'),
                  selected: _sameCalendarDay(
                    effectiveDate,
                    DateTime.now().add(const Duration(days: 1)),
                  ),
                  onSelected: saving ? null : (_) => _selectTomorrow(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: saving ? null : _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Price effective from',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  '${effectiveDate.day.toString().padLeft(2, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mrpCtrl,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'MRP (optional)',
                prefixText: '₹ ',
                helperText: 'Maximum retail price printed on pack',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'GST Slab',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: slabs
                  .map(
                    (slab) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: ChoiceChip(
                          label: Text(
                            '$slab%',
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: gst == slab,
                          onSelected: saving
                              ? null
                              : (_) => setState(() => gst = slab),
                          selectedColor: violet,
                          labelStyle: TextStyle(
                            color: gst == slab ? Colors.white : ink,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(color: red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryAction(
              saving ? 'Updating prices…' : 'Update Prices',
              icon: saving ? null : Icons.check_rounded,
              onPressed: saving ? null : _save,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Product'),
              style: OutlinedButton.styleFrom(foregroundColor: red),
            ),
          ],
        ),
      ),
    ),
  );

  void _selectToday() {
    final now = DateTime.now();
    setState(() => effectiveDate = DateTime(now.year, now.month, now.day));
  }

  void _selectTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    setState(
      () =>
          effectiveDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => effectiveDate = picked);
  }

  Future<void> _save() async {
    final sellingPrice = double.tryParse(sellingCtrl.text.trim());
    if (sellingPrice == null || sellingPrice <= 0) {
      setState(() => errorText = 'Enter a valid selling price.');
      return;
    }
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      await widget.state.scheduleProductPrice(productId, {
        'selling_price': sellingCtrl.text.trim(),
        'purchase_price': purchaseCtrl.text.trim().isEmpty
            ? '0'
            : purchaseCtrl.text.trim(),
        'tax_percent': gst.toString(),
        'effective_date':
            '${effectiveDate.year.toString().padLeft(4, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}',
      });
      final mrp = mrpCtrl.text.trim();
      await widget.state.updateProduct(productId, {
        'mrp': mrp.isEmpty ? null : mrp,
      });
      if (mounted) Navigator.pop(context, _PriceSheetResult.updated);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        saving = false;
        errorText = error.toString();
      });
    }
  }

  Future<void> _delete() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete product?'),
            content: Text(
              'Delete ${widget.product['name']} permanently? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(backgroundColor: red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      await widget.state.deleteProduct(productId);
      if (mounted) Navigator.pop(context, _PriceSheetResult.deleted);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        saving = false;
        errorText = error.toString();
      });
    }
  }
}

Future<void> _showProductFilters(BuildContext context, AdminState state) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Catalog filters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Show products by current availability.',
              style: TextStyle(fontSize: 11, color: muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                  .map(
                    (filter) => ChoiceChip(
                      label: Text(filter),
                      selected: state.productStockFilter == filter,
                      onSelected: (_) {
                        state.setProductStockFilter(filter);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
