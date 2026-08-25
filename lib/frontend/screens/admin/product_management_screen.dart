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
    while (
      mounted && widget.state.refreshing && widget.state.products.isEmpty
    ) {
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
        product['category_name'],
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

class _MobileProductList extends StatelessWidget {
  const _MobileProductList({required this.state, required this.products});

  final AdminState state;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: SearchBox(
          'Search by name, SKU or barcode',
          trailing: Icons.filter_alt_outlined,
          onTrailingTap: () => _showProductFilters(context, state),
          onChanged: state.setProductQuery,
        ),
      ),
      Expanded(
        child: products.isEmpty
            ? const _EmptyState(
                'No products found.',
                icon: Icons.inventory_2_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                itemCount: products.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final status = product['stock_status']?.toString() ?? '';
                  return ListTile(
                    minTileHeight: 72,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    onTap: () => _showEditPriceSheet(context, state, product),
                    leading: InkWell(
                      onTap: () =>
                          _replaceProductImage(context, state, product),
                      child: SizedBox.square(
                        dimension: 52,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _ProductImage(
                            url: _productImageUrl(state, product['image']),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      product['name']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${product['brand_name']?.toString().isNotEmpty == true ? '${product['brand_name']} • ' : ''}SKU: ${product['sku'] ?? '—'}\nStore: ${product['store_stock'] ?? 0}  |  Shelf: ${product['shelf_stock'] ?? 0}  |  Total: ${product['total_stock'] ?? product['stock_quantity'] ?? 0}',
                        style: const TextStyle(fontSize: 9, height: 1.45),
                      ),
                    ),
                    trailing: _StockBadge(status: status),
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
                        if ('${product['store_section'] ?? ''}${product['rack_location'] ?? ''}'.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: blue),
                            const SizedBox(width: 3),
                            Flexible(child: Text(
                              [product['store_section'], product['rack_location']]
                                  .where((value) => value != null && value.toString().trim().isNotEmpty)
                                  .join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: blue, fontSize: 9, fontWeight: FontWeight.w700),
                            )),
                          ]),
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

Future<void> _showEditPriceSheet(
  BuildContext context,
  AdminState state,
  Map<String, dynamic> product,
) async {
  final productId = product['id'] as int;
  final sellingCtrl = TextEditingController(
    text: product['selling_price']?.toString() ?? '',
  );
  final purchaseCtrl = TextEditingController(
    text: product['purchase_price']?.toString() ?? '',
  );
  final mrpCtrl = TextEditingController(text: product['mrp']?.toString() ?? '');
  var effectiveDate = DateTime.now();
  var gst =
      int.tryParse(
        double.tryParse(
              product['tax_percent']?.toString() ?? '',
            )?.toStringAsFixed(0) ??
            '0',
      ) ??
      0;
  // Snap to a valid slab
  const slabs = [0, 5, 12, 18, 28];
  if (!slabs.contains(gst)) gst = 18;

  var saving = false;
  String? errorText;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.edit_outlined, color: blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product['name']?.toString() ?? 'Edit Prices',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose when this purchase price, selling price and GST should start.',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
            const SizedBox(height: 16),

            // ── Price fields ─────────────────────────────────────────────
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
            InkWell(
              onTap: saving ? null : () async {
                final picked = await showDatePicker(context: sheetCtx, initialDate: effectiveDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (picked != null) setSheet(() => effectiveDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Price effective from', prefixIcon: Icon(Icons.calendar_month_outlined)),
                child: Text('${effectiveDate.day.toString().padLeft(2, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.year}'),
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

            // ── GST slab ─────────────────────────────────────────────────
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
                              : (_) => setSheet(() => gst = slab),
                          selectedColor: blue,
                          labelStyle: TextStyle(
                            color: gst == slab ? Colors.white : ink,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            // ── Error ────────────────────────────────────────────────────
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(color: red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 20),

            // ── Save button ──────────────────────────────────────────────
            PrimaryAction(
              saving ? 'Updating prices…' : 'Update Prices',
              icon: saving ? null : Icons.check_rounded,
              onPressed: saving
                  ? null
                  : () async {
                      final sp = double.tryParse(sellingCtrl.text.trim());
                      if (sp == null || sp <= 0) {
                        setSheet(
                          () => errorText = 'Enter a valid selling price.',
                        );
                        return;
                      }
                      setSheet(() {
                        saving = true;
                        errorText = null;
                      });
                      try {
                        final body = <String, dynamic>{
                          'selling_price': sellingCtrl.text.trim(),
                          'purchase_price': purchaseCtrl.text.trim().isEmpty ? '0' : purchaseCtrl.text.trim(),
                          'tax_percent': gst.toString(),
                          'effective_date': '${effectiveDate.year.toString().padLeft(4, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}',
                        };
                        final mrp = mrpCtrl.text.trim();
                        await state.scheduleProductPrice(productId, body);
                        await state.updateProduct(productId, {'mrp': mrp.isEmpty ? null : mrp});
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        if (context.mounted) {
                          showNotice(
                            context,
                            'Prices updated — open quotations recalculated.',
                          );
                        }
                      } catch (e) {
                        setSheet(() {
                          saving = false;
                          errorText = e.toString();
                        });
                      }
                    },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: saving ? null : () async {
                final confirmed = await showDialog<bool>(context: sheetCtx, builder: (dialogContext) => AlertDialog(title: const Text('Delete product?'), content: Text('Delete ${product['name']} permanently? This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: red), child: const Text('Delete'))])) ?? false;
                if (!confirmed) return;
                try {
                  await state.deleteProduct(productId);
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  if (context.mounted) showNotice(context, 'Product deleted.');
                } catch (error) {
                  setSheet(() => errorText = error.toString());
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Product'),
              style: OutlinedButton.styleFrom(foregroundColor: red),
            ),
          ],
        ),
      ),
    ),
  );

  sellingCtrl.dispose();
  purchaseCtrl.dispose();
  mrpCtrl.dispose();
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
