part of 'admin_screens.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _categoryTabs = [];

  @override
  void initState() {
    super.initState();
    _categoryTabs = ['All'];
    for (final c in widget.state.categories) {
      final name = c['name']?.toString() ?? '';
      if (name.isNotEmpty) _categoryTabs.add(name);
    }
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
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
    final query = state.productQuery.trim().toLowerCase();

    final allProducts = state.products.where((product) {
      final searchable = [
        product['name'],
        product['sku'],
        product['category_name'],
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
      final cost =
          double.tryParse(p['purchase_price']?.toString() ?? '') ?? 0;
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
      child: Column(
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
                    onTrailingTap: () => _showProductFilters(context, state),
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
              tabs: _categoryTabs
                  .map((t) => Tab(text: t))
                  .toList(),
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
                : _ProductGrid(
                    state: state,
                    products: allProducts,
                  ),
          ),
        ],
      ),
    );
  }
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
              onImageTap: () =>
                  _replaceProductImage(context, state, product),
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
                        product['category_name']?.toString().toUpperCase() ??
                            'UNCATEGORIZED',
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
                  '${product['stock_quantity'] ?? 0} in stock',
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
              ],
            ),
          ],
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
