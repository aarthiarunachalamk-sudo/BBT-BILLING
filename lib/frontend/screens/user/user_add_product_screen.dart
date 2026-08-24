part of 'user_screens.dart';

class UserAddProductScreen extends StatefulWidget {
  const UserAddProductScreen(this.state, {super.key});
  final UserState state;
  @override
  State<UserAddProductScreen> createState() => _UserAddProductScreenState();
}

class _UserAddProductScreenState extends State<UserAddProductScreen> {
  final formKey = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final name in ['name', 'sku', 'barcode', 'purchase_price', 'selling_price', 'tax_percent', 'store_stock', 'shelf_stock', 'target_shelf_quantity', 'reorder_level', 'batch_number', 'manufactured_date', 'expiry_date'])
      name: TextEditingController(),
  };
  int? category;
  XFile? productImage;
  Uint8List? imagePreview;

  @override
  void dispose() {
    for (final controller in fields.values) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UserShell(
    state: widget.state,
    title: 'Add Product',
    showBack: true,
    child: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _text('name', 'Product Name'), _text('sku', 'SKU'),
          _text('barcode', 'Barcode', isRequired: false),
          DropdownButtonFormField<int>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: widget.state.categories.map((row) => DropdownMenuItem<int>(value: row['id'] as int, child: Text('${row['name']}'))).toList(),
            onChanged: (value) => setState(() => category = value),
            validator: (value) => value == null ? 'Select a category.' : null,
          ),
          const SizedBox(height: 10),
          _imagePicker(),
          const SizedBox(height: 10),
          _text('purchase_price', 'Purchase Price', numeric: true),
          _text('selling_price', 'Selling Price', numeric: true),
          _text('tax_percent', 'GST %', numeric: true, initial: '5'),
          _text('store_stock', 'Store Quantity', numeric: true, initial: '0'),
          _text('shelf_stock', 'Shelf Quantity', numeric: true, initial: '0'),
          _text('target_shelf_quantity', 'Shelf Target Quantity', numeric: true, initial: '0'),
          _text('reorder_level', 'Minimum Stock', numeric: true, initial: '5'),
          _text('batch_number', 'Batch Number', isRequired: false),
          _dateField('manufactured_date', 'Manufacturing Date', firstDate: DateTime(2000), lastDate: DateTime.now()),
          _dateField('expiry_date', 'Expiry Date', firstDate: DateTime.now(), lastDate: DateTime(2100)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: widget.state.loading ? null : _save, child: const Text('Save Product')),
        ],
      ),
    ),
  );

  Widget _text(String key, String label, {bool numeric = false, bool isRequired = true, String? initial}) {
    if (fields[key]!.text.isEmpty && initial != null) fields[key]!.text = initial;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: fields[key],
        keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: isRequired ? (value) => value == null || value.trim().isEmpty ? '$label is required.' : null : null,
      ),
    );
  }

  Widget _imagePicker() => UserCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Photo', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Capture a clear photo or choose one from the gallery.', style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
        const SizedBox(height: 10),
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imagePreview == null
                  ? const ColoredBox(color: Color(0xFFEAF1FA), child: Icon(Icons.inventory_2_outlined, color: userBlue, size: 30))
                  : Image.memory(imagePreview!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera')),
            OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery')),
          ])),
        ]),
      ],
    ),
  );

  Widget _dateField(String key, String label, {required DateTime firstDate, required DateTime lastDate}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: fields[key],
      readOnly: true,
      onTap: () async {
        final initial = DateTime.tryParse(fields[key]!.text) ?? DateTime.now();
        final selected = await showDatePicker(context: context, firstDate: firstDate, lastDate: lastDate, initialDate: initial.isBefore(firstDate) ? firstDate : initial.isAfter(lastDate) ? lastDate : initial);
        if (selected != null) setState(() => fields[key]!.text = _apiDate(selected));
      },
      decoration: InputDecoration(labelText: label, hintText: 'Select date', prefixIcon: const Icon(Icons.calendar_month_outlined)),
    ),
  );

  String _apiDate(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) setState(() { productImage = image; imagePreview = bytes; });
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final store = int.tryParse(fields['store_stock']!.text) ?? 0;
    final shelf = int.tryParse(fields['shelf_stock']!.text) ?? 0;
    final body = <String, dynamic>{
      'item_type': 'material', 'name': fields['name']!.text.trim(), 'sku': fields['sku']!.text.trim(),
      'barcode': fields['barcode']!.text.trim().isEmpty ? null : fields['barcode']!.text.trim(), 'category': category,
      'unit': 'unit', 'purchase_price': fields['purchase_price']!.text, 'selling_price': fields['selling_price']!.text,
      'tax_percent': fields['tax_percent']!.text, 'store_stock': store, 'shelf_stock': shelf,
      'target_shelf_quantity': int.tryParse(fields['target_shelf_quantity']!.text) ?? shelf,
      'stock_quantity': store + shelf, 'reorder_level': int.tryParse(fields['reorder_level']!.text) ?? 5, 'is_active': true,
      if (fields['batch_number']!.text.trim().isNotEmpty) 'batch_number': fields['batch_number']!.text.trim(),
      if (fields['manufactured_date']!.text.trim().isNotEmpty) 'manufactured_date': fields['manufactured_date']!.text.trim(),
      if (fields['expiry_date']!.text.trim().isNotEmpty) 'expiry_date': fields['expiry_date']!.text.trim(),
    };
    final success = await widget.state.createProduct(body, image: productImage);
    if (mounted) _notice(context, success ? 'Product created and shared with Admin.' : widget.state.error ?? 'Unable to create product.');
  }
}
