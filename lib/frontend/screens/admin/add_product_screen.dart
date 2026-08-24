part of 'admin_screens.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final sku = TextEditingController();
  final purchasePrice = TextEditingController();
  final sellingPrice = TextEditingController();
  final stock = TextEditingController(text: '0');
  final shelfStock = TextEditingController(text: '0');
  final shelfTarget = TextEditingController(text: '0');
  final reorderLevel = TextEditingController(text: '5');
  final expiryDate = TextEditingController();
  final mrp = TextEditingController();
  final priceSource = TextEditingController();
  final priceVerifiedAt = TextEditingController();
  final Map<String, TextEditingController> manualDetails = {};
  int gst = 0;
  int? categoryId;
  int? brandId;
  String? unit;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    // Use pending category passed from the category screen, then clear it.
    if (widget.state.pendingCategoryId != null) {
      categoryId = widget.state.pendingCategoryId;
      widget.state.pendingCategoryId = null;
    } else if (widget.state.categories.isNotEmpty) {
      categoryId = widget.state.categories.first['id'] as int?;
    } else {
      unawaited(_loadCategories());
    }
    final activeBrands = _availableBrands;
    if (activeBrands.isNotEmpty) brandId = activeBrands.first['id'] as int?;
  }

  Future<void> _loadCategories() async {
    final loaded = await widget.state.refreshCategories();
    if (!mounted || !loaded || widget.state.categories.isEmpty) return;
    setState(() {
      categoryId ??= widget.state.categories.first['id'] as int?;
    });
  }

  @override
  void dispose() {
    name.dispose();
    sku.dispose();
    purchasePrice.dispose();
    sellingPrice.dispose();
    stock.dispose();
    shelfStock.dispose();
    shelfTarget.dispose();
    reorderLevel.dispose();
    expiryDate.dispose();
    mrp.dispose();
    priceSource.dispose();
    priceVerifiedAt.dispose();
    for (final controller in manualDetails.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String get _selectedCategoryName {
    if (categoryId == null) return '';
    final match = widget.state.categories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => {},
    );
    return match['name']?.toString() ?? '';
  }

  List<_ManualDetailField> get _categoryDetailFields => _manualDetailFieldsFor(
    _selectedCategoryName,
  ).where((field) => field.key != 'brand').toList();

  String get _selectedBrandName {
    final match = widget.state.brands.where((brand) => brand['id'] == brandId);
    return match.isEmpty ? '' : match.first['name']?.toString() ?? '';
  }

  List<Map<String, dynamic>> get _availableBrands =>
      widget.state.brands.where((brand) {
        if (brand['is_active'] != true) return false;
        final categories = (brand['category_names'] as List? ?? const []).map(
          (value) => value.toString().toLowerCase(),
        );
        return _selectedCategoryName.isEmpty ||
            categories.contains(_selectedCategoryName.toLowerCase());
      }).toList();

  TextEditingController _manualDetailController(String key) =>
      manualDetails.putIfAbsent(key, TextEditingController.new);

  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
    });
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? moneyValidator(String? value, {required bool allowZero}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final amount = double.tryParse(value.trim());
    if (amount == null) return 'Enter a valid amount';
    if (amount < 0 || (!allowZero && amount == 0)) {
      return allowZero ? 'Cannot be negative' : 'Must be greater than zero';
    }
    return null;
  }

  String? stockValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final amount = int.tryParse(value.trim());
    if (amount == null) return 'Enter a whole number';
    if (amount < 0) return 'Cannot be negative';
    return null;
  }

  String? expiryValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final date = DateTime.tryParse(value.trim());
    if (date == null) return 'Use YYYY-MM-DD';
    final today = DateTime.now();
    if (date.isBefore(DateTime(today.year, today.month, today.day))) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  Future<void> _pickDate(TextEditingController controller, {required DateTime firstDate, required DateTime lastDate}) async {
    final parsed = DateTime.tryParse(controller.text);
    final selected = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: parsed == null ? DateTime.now() : parsed.isBefore(firstDate) ? firstDate : parsed.isAfter(lastDate) ? lastDate : parsed,
    );
    if (selected != null) controller.text = '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
  }

  String? dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim()) == null ? 'Use YYYY-MM-DD' : null;
  }

  Future<void> addCategory() async {
    final category = await _showAddCategoryDialog(context, widget.state);
    if (!mounted || category == null) return;
    setState(() => categoryId = category['id'] as int?);
  }

  Future<void> saveProduct() async {
    if (saving || formKey.currentState?.validate() != true) return;
    if (categoryId == null) {
      showNotice(context, 'Select a category first.');
      return;
    }
    setState(() => saving = true);
    try {
      final product = await widget.state.createProduct(
        {
          'item_type': 'material',
          'name': name.text.trim(),
          'sku': sku.text.trim(),
          'category': categoryId,
          if (brandId != null) 'brand': brandId,
          'manual_details': {
            if (_selectedBrandName.isNotEmpty) 'brand': _selectedBrandName,
            for (final field in _categoryDetailFields)
              if (_manualDetailController(field.key).text.trim().isNotEmpty)
                field.key: _manualDetailController(field.key).text.trim(),
          },
          'unit': unit ?? 'Pack',
          'purchase_price': purchasePrice.text.trim(),
          'selling_price': sellingPrice.text.trim(),
          if (mrp.text.trim().isNotEmpty) 'mrp': mrp.text.trim(),
          if (priceSource.text.trim().isNotEmpty)
            'price_source_url': priceSource.text.trim(),
          if (priceVerifiedAt.text.trim().isNotEmpty)
            'price_verified_at': priceVerifiedAt.text.trim(),
          'tax_percent': gst.toString(),
          'store_stock': int.parse(stock.text.trim()),
          'shelf_stock': int.parse(shelfStock.text.trim()),
          'target_shelf_quantity': int.parse(shelfTarget.text.trim()),
          'stock_quantity': int.parse(stock.text.trim()) + int.parse(shelfStock.text.trim()),
          'reorder_level': int.parse(reorderLevel.text.trim()),
          if (expiryDate.text.trim().isNotEmpty)
            'expiry_date': expiryDate.text.trim(),
          'is_active': true,
        },
        imageBytes: selectedImageBytes,
        imageName: selectedImage?.name,
      );
      if (!mounted) return;
      setState(() => saving = false);
      showNotice(
        context,
        '${product['name'] ?? 'Product'} added to $_selectedCategoryName.',
      );
      widget.state.go(4);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      showNotice(context, error.toString());
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Add Product',
    back: 4,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: widget.state.categories.isEmpty
              ? _NoCategoryPlaceholder(onAdd: addCategory)
              : Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      // ── CATEGORY (most important — shown first) ──────────
                      const _SectionHeader(
                        icon: Icons.category_outlined,
                        title: 'Category',
                        caption: 'Which category does this product belong to?',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              key: ValueKey(
                                'cat-$categoryId-${widget.state.categories.length}',
                              ),
                              initialValue: categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  size: 18,
                                ),
                              ),
                              items: widget.state.categories
                                  .map(
                                    (c) => DropdownMenuItem<int>(
                                      value: c['id'] as int,
                                      child: Text(c['name']?.toString() ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (v) => setState(() {
                                      categoryId = v;
                                      brandId = null;
                                      unit = null;
                                    }),
                              validator: (v) =>
                                  v == null ? 'Select a category' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Create new category',
                            child: IconButton.filled(
                              onPressed: saving ? null : addCategory,
                              icon: const Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── IMAGE + NAME ─────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.sell_outlined,
                        title: 'Product details',
                        caption: 'Name, image and barcode.',
                      ),
                      const SizedBox(height: 12),

                      // Image picker row
                      SectionCard(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: saving ? null : pickImage,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox.square(
                                  dimension: 82,
                                  child: selectedImageBytes == null
                                      ? const ColoredBox(
                                          color: page,
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: blue,
                                            size: 30,
                                          ),
                                        )
                                      : Image.memory(
                                          selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Product image',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'JPG or PNG. Clear front-facing pack shot.',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: saving ? null : pickImage,
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      selectedImage == null
                                          ? 'Choose image'
                                          : 'Replace image',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: brandId,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                prefixIcon: Icon(
                                  Icons.branding_watermark_outlined,
                                  size: 18,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('No brand / Generic'),
                                ),
                                ..._availableBrands.map(
                                  (brand) => DropdownMenuItem<int?>(
                                    value: brand['id'] as int,
                                    child: Text(brand['name'].toString()),
                                  ),
                                ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (value) => setState(() => brandId = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Manage brands',
                            child: IconButton.filledTonal(
                              onPressed: saving
                                  ? null
                                  : () => widget.state.go(19),
                              icon: const Icon(Icons.add_business_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: name,
                        validator: requiredText,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'Example: Turmeric Powder 250g',
                          prefixIcon: Icon(Icons.label_outline, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: sku,
                        validator: requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Barcode / SKU *',
                          prefixIcon: Icon(Icons.qr_code_scanner, size: 18),
                          suffixIcon: Icon(Icons.qr_code_scanner, color: blue),
                        ),
                      ),

                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.edit_note_outlined,
                        title: '$_selectedCategoryName details',
                        caption:
                            'Enter the product information for this category.',
                      ),
                      const SizedBox(height: 12),
                      ..._categoryDetailFields.map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: _manualDetailController(field.key),
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: field.label,
                              hintText: field.hint,
                              prefixIcon: Icon(field.icon, size: 18),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── PRICING ──────────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.currency_rupee_rounded,
                        title: 'Pricing',
                        caption: 'Purchase cost, selling price and MRP.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: purchasePrice,
                              validator: (v) =>
                                  moneyValidator(v, allowZero: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Purchase Price (₹) *',
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: sellingPrice,
                              validator: (v) =>
                                  moneyValidator(v, allowZero: false),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (₹) *',
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: mrp,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? null
                            : moneyValidator(v, allowZero: false),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'MRP (optional)',
                          prefixText: '₹ ',
                          helperText: 'Maximum retail price printed on pack',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── STOCK & UNIT ─────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.inventory_2_outlined,
                        title: 'Stock & unit',
                        caption: 'Opening quantity, minimum level and unit.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stock,
                              validator: stockValidator,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Initial Store Stock *',
                                prefixIcon: Icon(
                                  Icons.inventory_outlined,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: reorderLevel,
                              validator: stockValidator,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Minimum Stock *',
                                prefixIcon: Icon(
                                  Icons.warning_amber_outlined,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: shelfStock,
                          validator: stockValidator,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Initial Shelf Stock *', prefixIcon: Icon(Icons.shelves, size: 18)),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(
                          controller: shelfTarget,
                          validator: stockValidator,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Shelf Target *', prefixIcon: Icon(Icons.track_changes, size: 18)),
                        )),
                      ]),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          prefixIcon: Icon(Icons.straighten, size: 18),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Pack', child: Text('Pack')),
                          DropdownMenuItem(
                            value: 'Piece',
                            child: Text('Piece'),
                          ),
                          DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                          DropdownMenuItem(value: 'Gram', child: Text('Gram')),
                          DropdownMenuItem(
                            value: 'Litre',
                            child: Text('Litre'),
                          ),
                          DropdownMenuItem(value: 'Box', child: Text('Box')),
                          DropdownMenuItem(
                            value: 'Dozen',
                            child: Text('Dozen'),
                          ),
                        ],
                        onChanged: (v) => setState(() => unit = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),

                      const SizedBox(height: 20),

                      // ── TAX ──────────────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.receipt_long_outlined,
                        title: 'GST slab',
                        caption: 'Select the applicable GST rate.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [0, 5, 12, 18, 28]
                            .map(
                              (value) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: ChoiceChip(
                                    label: Text(
                                      '$value%',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    selected: gst == value,
                                    onSelected: (_) =>
                                        setState(() => gst = value),
                                    selectedColor: blue,
                                    labelStyle: TextStyle(
                                      color: gst == value ? Colors.white : ink,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      // ── OPTIONAL FIELDS ──────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.tune_outlined,
                        title: 'Optional details',
                        caption: 'Expiry date and price verification.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: expiryDate,
                        validator: expiryValidator,
                        readOnly: true,
                        onTap: () => _pickDate(expiryDate, firstDate: DateTime.now(), lastDate: DateTime(2100)),
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: priceSource,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Price source URL',
                          prefixIcon: Icon(Icons.link, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: priceVerifiedAt,
                        validator: dateValidator,
                        readOnly: true,
                        onTap: () => _pickDate(priceVerifiedAt, firstDate: DateTime(2000), lastDate: DateTime.now()),
                        decoration: const InputDecoration(
                          labelText: 'Price verified date',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.calendar_month_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
        ),

        // ── Bottom action bar ─────────────────────────────────────────────
        if (widget.state.categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: line)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D10264D),
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryAction(
                      'Cancel',
                      outlined: true,
                      onPressed: saving ? null : () => widget.state.go(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryAction(
                      saving ? 'Saving…' : 'Save Product',
                      icon: saving ? null : Icons.check_rounded,
                      onPressed: saving ? null : saveProduct,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

// ── No-category placeholder ───────────────────────────────────────────────────

class _NoCategoryPlaceholder extends StatelessWidget {
  const _NoCategoryPlaceholder({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, size: 52, color: muted),
          const SizedBox(height: 14),
          const Text(
            'Create a category before adding a product.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 260,
            child: PrimaryAction(
              'Add Category',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Section header ────────────────────────────────────────────────────────────

class _ManualDetailField {
  const _ManualDetailField(this.key, this.label, this.hint, this.icon);

  final String key;
  final String label;
  final String hint;
  final IconData icon;
}

List<_ManualDetailField> _manualDetailFieldsFor(String category) {
  final value = category.toLowerCase();
  if (value.contains('beverage') ||
      value.contains('drink') ||
      value.contains('juice')) {
    return const [
      _ManualDetailField(
        'brand',
        'Brand',
        'Example: Tropicana',
        Icons.business_outlined,
      ),
      _ManualDetailField(
        'volume',
        'Volume',
        'Example: 1 L',
        Icons.local_drink_outlined,
      ),
      _ManualDetailField(
        'flavour',
        'Flavour',
        'Example: Mango',
        Icons.spa_outlined,
      ),
      _ManualDetailField(
        'packaging',
        'Packaging',
        'Bottle, can or carton',
        Icons.inventory_2_outlined,
      ),
    ];
  }
  if (value.contains('oil') ||
      value.contains('grocery') ||
      value.contains('food') ||
      value.contains('spice') ||
      value.contains('snack')) {
    return const [
      _ManualDetailField(
        'brand',
        'Brand',
        'Example: Fortune',
        Icons.business_outlined,
      ),
      _ManualDetailField(
        'net_weight',
        'Net weight',
        'Example: 500 g',
        Icons.scale_outlined,
      ),
      _ManualDetailField(
        'variant',
        'Variant / type',
        'Example: Refined',
        Icons.tune_outlined,
      ),
      _ManualDetailField(
        'ingredients',
        'Ingredients',
        'Main ingredients',
        Icons.restaurant_outlined,
      ),
    ];
  }
  if (value.contains('dairy') || value.contains('milk')) {
    return const [
      _ManualDetailField(
        'brand',
        'Brand',
        'Example: Amul',
        Icons.business_outlined,
      ),
      _ManualDetailField(
        'quantity',
        'Quantity',
        'Example: 500 ml',
        Icons.scale_outlined,
      ),
      _ManualDetailField(
        'fat_content',
        'Fat content',
        'Example: 3%',
        Icons.percent_outlined,
      ),
      _ManualDetailField(
        'storage',
        'Storage instructions',
        'Keep refrigerated',
        Icons.ac_unit_outlined,
      ),
    ];
  }
  if (value.contains('house') ||
      value.contains('clean') ||
      value.contains('personal')) {
    return const [
      _ManualDetailField(
        'brand',
        'Brand',
        'Product brand',
        Icons.business_outlined,
      ),
      _ManualDetailField(
        'size',
        'Size / quantity',
        'Example: 500 ml',
        Icons.straighten,
      ),
      _ManualDetailField(
        'material',
        'Material / formulation',
        'Material or formulation',
        Icons.science_outlined,
      ),
      _ManualDetailField(
        'usage',
        'Usage instructions',
        'How the product is used',
        Icons.info_outline,
      ),
    ];
  }
  return const [
    _ManualDetailField(
      'brand',
      'Brand',
      'Product brand',
      Icons.business_outlined,
    ),
    _ManualDetailField(
      'variant',
      'Variant / model',
      'Product variant or model',
      Icons.tune_outlined,
    ),
    _ManualDetailField(
      'size',
      'Size / quantity',
      'Example: Large, 500 g or 1 L',
      Icons.straighten,
    ),
    _ManualDetailField(
      'additional_info',
      'Additional information',
      'Any category-specific detail',
      Icons.notes_outlined,
    ),
  ];
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: blue),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(caption, style: const TextStyle(fontSize: 9, color: muted)),
          ],
        ),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

// Keep old name for backward compat with any existing references — removed.
