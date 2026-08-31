part of 'admin_screens.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

enum _StickerPlacement { topLeft, topRight, bottomLeft, bottomRight }

extension on _StickerPlacement {
  String get label => switch (this) {
    _StickerPlacement.topLeft => 'Top left',
    _StickerPlacement.topRight => 'Top right',
    _StickerPlacement.bottomLeft => 'Bottom left',
    _StickerPlacement.bottomRight => 'Bottom right',
  };

  Alignment get alignment => switch (this) {
    _StickerPlacement.topLeft => Alignment.topLeft,
    _StickerPlacement.topRight => Alignment.topRight,
    _StickerPlacement.bottomLeft => Alignment.bottomLeft,
    _StickerPlacement.bottomRight => Alignment.bottomRight,
  };
}

class _AddProductScreenState extends State<AddProductScreen> {
  final stepKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final name = TextEditingController();
  final sku = TextEditingController();
  final purchasePrice = TextEditingController();
  final sellingPrice = TextEditingController();
  final mrp = TextEditingController();
  final openingStock = TextEditingController(text: '0');
  final labelCopies = TextEditingController(text: '1');
  String? rackLocation;
  XFile? productImage;
  Uint8List? productImageBytes;
  int? categoryId;
  int? gst;
  int currentStep = 0;
  bool saving = false;
  bool imageError = false;
  bool printAfterSave = true;
  String barcodeSource = 'Not selected';
  BarcodeLabelFormat labelFormat = BarcodeLabelFormat.compact50x25;
  _StickerPlacement stickerPlacement = _StickerPlacement.bottomRight;

  @override
  void initState() {
    super.initState();
    if (widget.state.pendingCategoryId != null) {
      categoryId = widget.state.pendingCategoryId;
      widget.state.pendingCategoryId = null;
    } else if (widget.state.categories.isNotEmpty) {
      categoryId = widget.state.categories.first['id'] as int?;
    } else {
      unawaited(_loadCategories());
    }
    if (widget.state.racks.isEmpty) unawaited(widget.state.refreshRacks());
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
    mrp.dispose();
    openingStock.dispose();
    labelCopies.dispose();
    super.dispose();
  }

  List<String> get _locationOptions {
    final names = <String>{
      for (final rack in widget.state.racks)
        if (rack['is_active'] != false &&
            '${rack['name'] ?? ''}'.trim().isNotEmpty)
          '${rack['name']}'.trim(),
      for (final product in widget.state.products)
        if ('${product['rack_name'] ?? product['rack_location'] ?? ''}'
            .trim()
            .isNotEmpty)
          '${product['rack_name'] ?? product['rack_location']}'.trim(),
    };
    if (names.isEmpty) {
      names.addAll(const ['Rack 1', 'Rack 2', 'Rack 3', 'Fridge']);
    }
    return names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  int? get _selectedRackId {
    for (final rack in widget.state.racks) {
      if ('${rack['name']}'.toLowerCase() == rackLocation?.toLowerCase()) {
        return int.tryParse('${rack['id']}');
      }
    }
    return null;
  }

  String get _selectedDepartmentName {
    for (final category in widget.state.categories) {
      if (int.tryParse('${category['id']}') == categoryId) {
        final name = '${category['name'] ?? ''}'.trim();
        if (name.isNotEmpty) return name;
      }
    }
    return 'General';
  }

  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Add Product',
    back: 4,
    bottom: false,
    child: widget.state.categories.isEmpty
        ? _NoCategoryPlaceholder(onAdd: _addCategory)
        : Column(
            children: [
              _AdminProductWorkflowHeader(currentStep: currentStep),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(currentStep),
                    child: _stepBody(),
                  ),
                ),
              ),
              _bottomActions(),
            ],
          ),
  );

  Widget _stepBody() => switch (currentStep) {
    0 => Form(
      key: stepKeys[0],
      child: _AdminStepSurface(
        icon: Icons.inventory_2_outlined,
        title: 'Product identity',
        caption: 'Enter only the details required to identify the product.',
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey(
                    'category-$categoryId-${widget.state.categories.length}',
                  ),
                  initialValue: categoryId,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: Colors.white,
                  elevation: 4,
                  decoration: const InputDecoration(
                    labelText: 'Department Name *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: widget.state.categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category['id'] as int,
                          child: Text('${category['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) => setState(() => categoryId = value),
                  validator: (value) =>
                      value == null ? 'Select a category.' : null,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Create category',
                child: IconButton.filled(
                  onPressed: saving ? null : _addCategory,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Product Name *',
              hintText: 'Example: Fresh Milk 1 L',
              prefixIcon: Icon(Icons.label_outline_rounded),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          _barcodeSetup(),
          const SizedBox(height: 16),
          _productImagePicker(),
        ],
      ),
    ),
    1 => Form(
      key: stepKeys[1],
      child: _AdminStepSurface(
        icon: Icons.currency_rupee_rounded,
        title: 'Product pricing',
        caption: 'Enter the buying cost and customer selling price.',
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                TextFormField(
                  controller: purchasePrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price *',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (value) => _price(value, allowZero: true),
                ),
                TextFormField(
                  controller: sellingPrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Selling Price *',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) => _price(value, allowZero: false),
                ),
              ];
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [
                    fields.first,
                    const SizedBox(height: 14),
                    fields.last,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields.first),
                  const SizedBox(width: 12),
                  Expanded(child: fields.last),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: mrp,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'MRP *',
              hintText: 'Maximum retail price',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.price_check_outlined),
            ),
            validator: _mrpValidator,
          ),
          const SizedBox(height: 20),
          _AdminGstSlabField(
            selected: gst,
            onChanged: (value) => setState(() => gst = value),
          ),
        ],
      ),
    ),
    2 => Form(
      key: stepKeys[2],
      child: _AdminStepSurface(
        icon: Icons.shelves,
        title: 'Stock placement',
        caption: 'Set the opening quantity and supermarket location.',
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = [
                TextFormField(
                  controller: openingStock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening Store Quantity *',
                    prefixIcon: Icon(Icons.inventory_outlined),
                  ),
                  validator: _stock,
                ),
                DropdownButtonFormField<String>(
                  initialValue: rackLocation,
                  isExpanded: true,
                  menuMaxHeight: 280,
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: Colors.white,
                  elevation: 4,
                  decoration: const InputDecoration(
                    labelText: 'Rack / Fridge Location *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  hint: const Text('Select location'),
                  items: _locationOptions
                      .map(
                        (location) => DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) => setState(() => rackLocation = value),
                  validator: (value) =>
                      value == null ? 'Select a location.' : null,
                ),
              ];
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [
                    fields.first,
                    const SizedBox(height: 14),
                    fields.last,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: fields.first),
                  const SizedBox(width: 12),
                  Expanded(child: fields.last),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: blue.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: blue.withValues(alpha: .15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: blue, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Shelf stock starts at 0. Unit and minimum stock use backend defaults and can be updated later.',
                    style: TextStyle(color: blue, fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    _ => _productStickerPreview(),
  };

  Widget _bottomActions() => Container(
    padding: const EdgeInsets.fromLTRB(16, 11, 16, 16),
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
              currentStep == 0 ? 'Cancel' : 'Back',
              outlined: true,
              onPressed: saving
                  ? null
                  : () {
                      if (currentStep == 0) {
                        widget.state.go(4);
                      } else {
                        setState(() => currentStep--);
                      }
                    },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryAction(
              saving
                  ? 'Saving…'
                  : currentStep == 3
                  ? 'Add Product'
                  : 'Continue',
              key: const Key('add-product-primary-action'),
              icon: saving
                  ? null
                  : currentStep == 3
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: saving ? null : _continue,
            ),
          ),
        ],
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _price(String? value, {required bool allowZero}) {
    if (value == null || value.trim().isEmpty) return 'Price is required.';
    final amount = double.tryParse(value.trim());
    if (amount == null) return 'Enter a valid price.';
    if (amount < 0 || (!allowZero && amount == 0)) {
      return allowZero ? 'Price cannot be negative.' : 'Enter a price above 0.';
    }
    return null;
  }

  String? _mrpValidator(String? value) {
    final error = _price(value, allowZero: false);
    if (error != null) return error;
    final retail = double.tryParse(sellingPrice.text.trim());
    final maximum = double.tryParse(value!.trim());
    if (retail != null && maximum != null && maximum < retail) {
      return 'MRP cannot be lower than selling price.';
    }
    return null;
  }

  String? _stock(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required.';
    final quantity = int.tryParse(value.trim());
    if (quantity == null) return 'Enter a whole number.';
    if (quantity < 0) return 'Quantity cannot be negative.';
    return null;
  }

  Future<void> _addCategory() async {
    final category = await _showAddCategoryDialog(context, widget.state);
    if (!mounted || category == null) return;
    setState(() => categoryId = category['id'] as int?);
  }

  Future<void> _scanBarcode() async {
    final code = await showBarcodeScanner(context);
    if (!mounted || code == null || code.trim().isEmpty) return;
    setState(() {
      sku.text = code.trim();
      barcodeSource = 'Scanned from product';
    });
  }

  void _generateBarcode() {
    setState(() {
      sku.text = generateEan13Barcode(widget.state.products);
      barcodeSource = 'Generated by BBT';
    });
  }

  String? _barcodeValidator(String? value) {
    final required = _required(value);
    if (required != null) return required;
    final normalized = value!.trim().toLowerCase();
    final duplicate = widget.state.products.any(
      (product) => [product['sku'], product['barcode']].any(
        (existing) => existing?.toString().trim().toLowerCase() == normalized,
      ),
    );
    return duplicate
        ? 'This barcode is already used by another product.'
        : null;
  }

  Widget _barcodeSetup() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F5FF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDCD4FF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE9E3FF),
              child: Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF6547D5),
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Barcode setup',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Scan an existing code or generate a new retail barcode.',
                    style: TextStyle(fontSize: 9.5, color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: sku,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Barcode Number / SKU *',
            hintText: 'Scan, generate or enter manually',
            prefixIcon: const Icon(Icons.numbers_rounded),
            suffixIcon: sku.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear barcode',
                    onPressed: saving
                        ? null
                        : () => setState(() {
                            sku.clear();
                            barcodeSource = 'Not selected';
                          }),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => setState(() => barcodeSource = 'Entered manually'),
          validator: _barcodeValidator,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan barcode'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6547D5),
                ),
                onPressed: saving ? null : _generateBarcode,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generate new'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          barcodeSource == 'Generated by BBT' && isValidEan13(sku.text)
              ? '$barcodeSource • Valid EAN-13'
              : barcodeSource,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF6547D5),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Divider(height: 24),
        const Text(
          'Print label setup',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<BarcodeLabelFormat>(
          initialValue: labelFormat,
          isExpanded: true,
          menuMaxHeight: 280,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          elevation: 4,
          decoration: const InputDecoration(
            labelText: 'Print format',
            prefixIcon: Icon(Icons.print_outlined),
          ),
          items: BarcodeLabelFormat.values
              .map(
                (format) => DropdownMenuItem(
                  value: format,
                  child: Text(
                    format.title,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: saving
              ? null
              : (value) => setState(() => labelFormat = value ?? labelFormat),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 5),
          child: Text(
            labelFormat.description,
            style: const TextStyle(fontSize: 8.8, color: muted),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: labelCopies,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Label copies',
                  prefixIcon: Icon(Icons.copy_all_outlined),
                ),
                validator: (value) {
                  final copies = int.tryParse(value?.trim() ?? '');
                  if (copies == null || copies < 1) {
                    return 'Enter 1 or more.';
                  }
                  if (copies >
                      (labelFormat == BarcodeLabelFormat.a4Sheet ? 96 : 20)) {
                    return 'Too many copies.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: const Text(
                    'Print after save',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Open print preview',
                    style: TextStyle(fontSize: 8.5),
                  ),
                  value: printAfterSave,
                  onChanged: saving
                      ? null
                      : (value) => setState(() => printAfterSave = value),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      productImage = image;
      productImageBytes = bytes;
      imageError = false;
    });
  }

  Widget _productImagePicker() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: page,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: imageError ? red : line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image *',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 72,
                child: productImageBytes == null
                    ? const ColoredBox(
                        color: Colors.white,
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: blue,
                          size: 28,
                        ),
                      )
                    : Image.memory(productImageBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (imageError) ...[
          const SizedBox(height: 7),
          const Text(
            'Add a product image to continue.',
            style: TextStyle(color: red, fontSize: 11),
          ),
        ],
      ],
    ),
  );

  Widget _productStickerPreview() => _AdminStepSurface(
    icon: Icons.preview_outlined,
    title: 'Product & sticker preview',
    caption:
        'Choose where the physical sticker should be placed before saving.',
    children: [
      Container(
        key: const Key('product-sticker-preview'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.25,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: productImageBytes == null
                          ? const Icon(
                              Icons.inventory_2_outlined,
                              size: 72,
                              color: muted,
                            )
                          : Image.memory(
                              productImageBytes!,
                              fit: BoxFit.contain,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: stickerPlacement.alignment,
                        child: _ProductStickerMockup(
                          productName: name.text.trim(),
                          barcode: sku.text.trim(),
                          price: mrp.text.trim(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 17, color: blue),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Preview guidance only. Keep the sticker away from the brand name, quantity, expiry date and product instructions.',
                    style: TextStyle(fontSize: 9.5, height: 1.35, color: muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Sticker position',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _StickerPlacement.values
            .map(
              (placement) => ChoiceChip(
                key: ValueKey('sticker-placement-${placement.name}'),
                avatar: Icon(
                  Icons.crop_free_rounded,
                  size: 15,
                  color: stickerPlacement == placement ? Colors.white : blue,
                ),
                label: Text(placement.label),
                selected: stickerPlacement == placement,
                selectedColor: blue,
                labelStyle: TextStyle(
                  color: stickerPlacement == placement ? Colors.white : ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: saving
                    ? null
                    : (_) => setState(() => stickerPlacement = placement),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            _previewDetail('Product', name.text.trim()),
            _previewDetail('Barcode / SKU', sku.text.trim()),
            _previewDetail('MRP', '₹${mrp.text.trim()}'),
            _previewDetail('Selling price', '₹${sellingPrice.text.trim()}'),
            _previewDetail('GST', '${gst ?? 0}%'),
            _previewDetail('Opening stock', openingStock.text.trim()),
            _previewDetail('Location', rackLocation ?? 'Not selected'),
            _previewDetail('Sticker format', labelFormat.title),
            _previewDetail('Copies', labelCopies.text.trim(), divider: false),
          ],
        ),
      ),
    ],
  );

  Widget _previewDetail(String label, String value, {bool divider = true}) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 9.5, color: muted),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (divider) const Divider(height: 1),
        ],
      );

  void _continue() {
    if (currentStep < stepKeys.length &&
        !(stepKeys[currentStep].currentState?.validate() ?? false)) {
      return;
    }
    if (currentStep == 0 && productImageBytes == null) {
      setState(() => imageError = true);
      return;
    }
    if (currentStep < 3) {
      setState(() => currentStep++);
      return;
    }
    _save();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final stock = int.parse(openingStock.text.trim());
      final product = await widget.state.createProduct(
        {
          'item_type': 'material',
          'name': name.text.trim(),
          'sku': sku.text.trim(),
          'barcode': sku.text.trim(),
          'category': categoryId,
          'store_section': _selectedDepartmentName,
          'purchase_price': purchasePrice.text.trim(),
          'selling_price': sellingPrice.text.trim(),
          'mrp': mrp.text.trim(),
          'tax_percent': gst,
          'manual_details': {
            'sticker_placement': stickerPlacement.name,
            'sticker_format': labelFormat.name,
          },
          if (_selectedRackId != null) 'rack': _selectedRackId,
          'rack_location': rackLocation,
          'store_stock': stock,
          'shelf_stock': 0,
          'stock_quantity': stock,
          'is_active': true,
        },
        imageBytes: productImageBytes,
        imageName: productImage?.name,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      showNotice(
        context,
        '${product['name'] ?? name.text.trim()} added successfully.',
      );
      // Saving is finished once the API has created the product. Dashboard
      // refresh and the platform print preview are follow-up work and must not
      // leave this form disabled with a permanent "Saving..." label.
      setState(() => saving = false);
      widget.state.go(4);
      if (printAfterSave) {
        unawaited(_printSavedProduct(product, messenger));
      }
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _printSavedProduct(
    Map<String, dynamic> product,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      await printBarcodeLabels(
        productName: product['name']?.toString() ?? name.text.trim(),
        barcode: product['barcode']?.toString() ?? sku.text.trim(),
        price: product['mrp']?.toString() ?? mrp.text.trim(),
        department: _selectedDepartmentName,
        format: labelFormat,
        copies: int.tryParse(labelCopies.text.trim()) ?? 1,
      );
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Product saved. Printer preview could not be opened.',
            ),
          ),
        );
      }
    }
  }
}

class _ProductStickerMockup extends StatelessWidget {
  const _ProductStickerMockup({
    required this.productName,
    required this.barcode,
    required this.price,
  });

  final String productName;
  final String barcode;
  final String price;

  @override
  Widget build(BuildContext context) => Container(
    width: 132,
    height: 72,
    padding: const EdgeInsets.fromLTRB(7, 5, 7, 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: ink, width: .8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                productName.isEmpty ? 'Product name' : productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'MRP ₹${price.isEmpty ? '0.00' : price}',
              style: const TextStyle(
                fontSize: 6.5,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Expanded(child: CustomPaint(painter: _StickerBarcodePainter())),
        const SizedBox(height: 2),
        Text(
          barcode.isEmpty ? '0000000000000' : barcode,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 6.5,
            letterSpacing: .7,
          ),
        ),
      ],
    ),
  );
}

class _StickerBarcodePainter extends CustomPainter {
  const _StickerBarcodePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    const pattern = [1.0, 2.0, 1.0, 1.0, 3.0, 1.0, 2.0, 1.0];
    var x = 0.0;
    var index = 0;
    while (x < size.width) {
      final width = pattern[index % pattern.length];
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      x += width + (index.isEven ? 1.4 : 1.0);
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminGstSlabField extends StatelessWidget {
  const _AdminGstSlabField({required this.selected, required this.onChanged});
  final int? selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => FormField<int>(
    initialValue: selected,
    validator: (value) => value == null ? 'Select a GST slab.' : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GST Slab *',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final slab in const [0, 5, 12, 18, 28])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: ChoiceChip(
                    label: Text('$slab%', style: const TextStyle(fontSize: 10)),
                    selected: selected == slab,
                    selectedColor: blue,
                    labelStyle: TextStyle(
                      color: selected == slab ? Colors.white : ink,
                    ),
                    onSelected: (_) {
                      field.didChange(slab);
                      onChanged(slab);
                    },
                  ),
                ),
              ),
          ],
        ),
        if (field.hasError) ...[
          const SizedBox(height: 5),
          Text(
            field.errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 11,
            ),
          ),
        ],
      ],
    ),
  );
}

class _AdminProductWorkflowHeader extends StatelessWidget {
  const _AdminProductWorkflowHeader({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Product', 'Pricing', 'Stock', 'Preview'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < labels.length; index++) ...[
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index <= currentStep ? blue : line,
                    ),
                  ),
                _AdminWorkflowDot(
                  number: index + 1,
                  label: labels[index],
                  active: index <= currentStep,
                  current: index == currentStep,
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Step ${currentStep + 1} of 4  •  ${currentStep == 3 ? 'Review before saving' : 'Mandatory fields only'}',
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminWorkflowDot extends StatelessWidget {
  const _AdminWorkflowDot({
    required this.number,
    required this.label,
    required this.active,
    required this.current,
  });
  final int number;
  final String label;
  final bool active;
  final bool current;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: current ? 34 : 30,
        height: current ? 34 : 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? blue : const Color(0xFFE8EDF4),
          shape: BoxShape.circle,
          border: current
              ? Border.all(color: const Color(0xFFBFD6F5), width: 3)
              : null,
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: active ? Colors.white : muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: current ? blue : muted,
          fontSize: 8,
          fontWeight: current ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}

class _AdminStepSurface extends StatelessWidget {
  const _AdminStepSurface({
    required this.icon,
    required this.title,
    required this.caption,
    required this.children,
  });
  final IconData icon;
  final String title;
  final String caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: blue),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caption,
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    ],
  );
}

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
          const Icon(Icons.category_outlined, size: 54, color: blue),
          const SizedBox(height: 16),
          const Text(
            'Create a category before adding a product.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Category'),
          ),
        ],
      ),
    ),
  );
}
