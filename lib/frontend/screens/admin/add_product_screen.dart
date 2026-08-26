part of 'admin_screens.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final stepKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final name = TextEditingController();
  final sku = TextEditingController();
  final purchasePrice = TextEditingController();
  final sellingPrice = TextEditingController();
  final openingStock = TextEditingController(text: '0');
  String? rackLocation;
  XFile? productImage;
  Uint8List? productImageBytes;
  int? categoryId;
  int? gst;
  int currentStep = 0;
  bool saving = false;
  bool imageError = false;

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
    openingStock.dispose();
    super.dispose();
  }

  List<String> get _locationOptions {
    final names = <String>{
      for (final rack in widget.state.racks)
        if (rack['is_active'] != false && '${rack['name'] ?? ''}'.trim().isNotEmpty)
          '${rack['name']}'.trim(),
      for (final product in widget.state.products)
        if ('${product['rack_name'] ?? product['rack_location'] ?? ''}'.trim().isNotEmpty)
          '${product['rack_name'] ?? product['rack_location']}'.trim(),
    };
    if (names.isEmpty) names.addAll(const ['Rack 1', 'Rack 2', 'Rack 3', 'Fridge']);
    return names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  int? get _selectedRackId {
    for (final rack in widget.state.racks) {
      if ('${rack['name']}'.toLowerCase() == rackLocation?.toLowerCase()) {
        return int.tryParse('${rack['id']}');
      }
    }
    return null;
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
                  decoration: const InputDecoration(
                    labelText: 'Category *',
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
          TextFormField(
            controller: sku,
            readOnly: true,
            onTap: saving ? null : _scanBarcode,
            decoration: InputDecoration(
              labelText: 'Barcode / SKU *',
              hintText: 'Tap scanner to capture code',
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
              suffixIcon: IconButton(
                tooltip: 'Scan barcode',
                onPressed: saving ? null : _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded, color: blue),
              ),
            ),
            validator: _required,
          ),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price *',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (value) => _price(value, allowZero: true),
                ),
                TextFormField(
                  controller: sellingPrice,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                  children: [fields.first, const SizedBox(height: 14), fields.last],
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
          const SizedBox(height: 20),
          _AdminGstSlabField(
            selected: gst,
            onChanged: (value) => setState(() => gst = value),
          ),
        ],
      ),
    ),
    _ => Form(
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
                  children: [fields.first, const SizedBox(height: 14), fields.last],
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
                  : currentStep == 2
                  ? 'Add Product'
                  : 'Continue',
              icon: saving
                  ? null
                  : currentStep == 2
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
    setState(() => sku.text = code.trim());
  }

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

  void _continue() {
    if (!(stepKeys[currentStep].currentState?.validate() ?? false)) return;
    if (currentStep == 0 && productImageBytes == null) {
      setState(() => imageError = true);
      return;
    }
    if (currentStep < 2) {
      setState(() => currentStep++);
      return;
    }
    _save();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final stock = int.parse(openingStock.text.trim());
      final product = await widget.state.createProduct({
        'item_type': 'material',
        'name': name.text.trim(),
        'sku': sku.text.trim(),
        'barcode': sku.text.trim(),
        'category': categoryId,
        'purchase_price': purchasePrice.text.trim(),
        'selling_price': sellingPrice.text.trim(),
        'tax_percent': gst,
        if (_selectedRackId != null) 'rack': _selectedRackId,
        'rack_location': rackLocation,
        'store_stock': stock,
        'shelf_stock': 0,
        'stock_quantity': stock,
        'is_active': true,
      }, imageBytes: productImageBytes, imageName: productImage?.name);
      if (!mounted) return;
      showNotice(context, '${product['name'] ?? name.text.trim()} added successfully.');
      widget.state.go(4);
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
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
    const labels = ['Product', 'Pricing', 'Placement'];
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
            'Step ${currentStep + 1} of 3  •  Mandatory fields only',
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
