part of 'user_screens.dart';

class UserAddProductScreen extends StatefulWidget {
  const UserAddProductScreen(this.state, {super.key});
  final UserState state;

  @override
  State<UserAddProductScreen> createState() => _UserAddProductScreenState();
}

class _UserAddProductScreenState extends State<UserAddProductScreen> {
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
  bool imageError = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.categories.isNotEmpty) {
      categoryId = widget.state.categories.first['id'] as int?;
    }
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
  Widget build(BuildContext context) => UserShell(
    state: widget.state,
    title: 'Add Product',
    showBack: true,
    child: Column(
      children: [
        _ProductWorkflowHeader(currentStep: currentStep),
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
      child: _StepSurface(
        icon: Icons.inventory_2_outlined,
        title: 'Product identity',
        caption: 'Enter the three details used to identify this product.',
        children: [
          DropdownButtonFormField<int>(
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
            onChanged: (value) => setState(() => categoryId = value),
            validator: (value) =>
                value == null ? 'Select a category.' : null,
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
            onTap: _scanBarcode,
            decoration: InputDecoration(
              labelText: 'Barcode / SKU *',
              hintText: 'Tap scanner to capture code',
              prefixIcon: const Icon(Icons.qr_code_2_rounded),
              suffixIcon: IconButton(
                tooltip: 'Scan barcode',
                onPressed: _scanBarcode,
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: userBlue,
                ),
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
      child: _StepSurface(
        icon: Icons.currency_rupee_rounded,
        title: 'Product pricing',
        caption: 'Enter the buying cost and customer selling price.',
        children: [
          TextFormField(
            controller: purchasePrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Purchase Price *',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
            validator: (value) => _price(value, allowZero: true),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: sellingPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Selling Price *',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            validator: (value) => _price(value, allowZero: false),
          ),
          const SizedBox(height: 20),
          _GstSlabField(
            selected: gst,
            onChanged: (value) => setState(() => gst = value),
          ),
        ],
      ),
    ),
    _ => Form(
      key: stepKeys[2],
      child: _StepSurface(
        icon: Icons.shelves,
        title: 'Stock placement',
        caption: 'Tell staff where to find the product in the supermarket.',
        children: [
          TextFormField(
            controller: openingStock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Opening Store Quantity *',
              prefixIcon: Icon(Icons.inventory_outlined),
            ),
            validator: _stock,
          ),
          const SizedBox(height: 14),
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
            onChanged: (value) => setState(() => rackLocation = value),
            validator: (value) =>
                value == null ? 'Select a location.' : null,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: userBlue.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: userBlue.withValues(alpha: .14)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: userBlue, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Shelf stock starts at 0. Minimum stock and unit use the supermarket defaults and can be updated later by Admin.',
                    style: TextStyle(
                      color: userBlue,
                      fontSize: 10,
                      height: 1.4,
                    ),
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
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFDCE3EC))),
      boxShadow: [
        BoxShadow(
          color: Color(0x120B2A5B),
          blurRadius: 14,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          if (currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.state.loading
                    ? null
                    : () => setState(() => currentStep--),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.state.loading ? null : _continue,
              icon: Icon(
                currentStep == 2
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(currentStep == 2 ? 'Add Product' : 'Continue'),
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
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: imageError ? userRed : const Color(0xFFDCE3EC),
      ),
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
                          color: userBlue,
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
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
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
            style: TextStyle(color: userRed, fontSize: 11),
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
    final stock = int.parse(openingStock.text.trim());
    final body = <String, dynamic>{
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
    };
    final success = await widget.state.createProduct(body, image: productImage);
    if (!mounted) return;
    if (success) {
      _notice(context, '${name.text.trim()} added successfully.');
      widget.state.go(UserPage.inventory);
    } else {
      _notice(
        context,
        widget.state.error ?? 'Unable to create product.',
      );
    }
  }
}

class _GstSlabField extends StatelessWidget {
  const _GstSlabField({required this.selected, required this.onChanged});

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
                    selectedColor: userBlue,
                    labelStyle: TextStyle(
                      color: selected == slab ? Colors.white : userNavy,
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

class _ProductWorkflowHeader extends StatelessWidget {
  const _ProductWorkflowHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Product', 'Pricing', 'Placement'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
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
                      color: index <= currentStep
                          ? userBlue
                          : const Color(0xFFDCE3EC),
                    ),
                  ),
                _WorkflowDot(
                  number: index + 1,
                  label: labels[index],
                  active: index <= currentStep,
                  current: index == currentStep,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Step ${currentStep + 1} of 3  •  Mandatory fields only',
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowDot extends StatelessWidget {
  const _WorkflowDot({
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
        decoration: BoxDecoration(
          color: active ? userBlue : const Color(0xFFE8EDF4),
          shape: BoxShape.circle,
          border: current ? Border.all(color: const Color(0xFFBFD6F5), width: 3) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: TextStyle(
            color: active ? Colors.white : Colors.blueGrey,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: current ? userBlue : Colors.blueGrey,
          fontSize: 8,
          fontWeight: current ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}

class _StepSurface extends StatelessWidget {
  const _StepSurface({
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
    padding: const EdgeInsets.all(14),
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE3EC)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0B2A5B),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: userBlue.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: userBlue),
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
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 10,
                        ),
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
    ],
  );
}
