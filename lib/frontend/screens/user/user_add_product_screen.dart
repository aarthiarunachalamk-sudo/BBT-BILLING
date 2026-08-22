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
          _text('purchase_price', 'Purchase Price', numeric: true),
          _text('selling_price', 'Selling Price', numeric: true),
          _text('tax_percent', 'GST %', numeric: true, initial: '5'),
          _text('store_stock', 'Store Quantity', numeric: true, initial: '0'),
          _text('shelf_stock', 'Shelf Quantity', numeric: true, initial: '0'),
          _text('target_shelf_quantity', 'Shelf Target Quantity', numeric: true, initial: '0'),
          _text('reorder_level', 'Minimum Stock', numeric: true, initial: '5'),
          _text('batch_number', 'Batch Number', isRequired: false),
          _text('manufactured_date', 'Manufacturing Date (YYYY-MM-DD)', isRequired: false),
          _text('expiry_date', 'Expiry Date (YYYY-MM-DD)', isRequired: false),
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
    final success = await widget.state.createProduct(body);
    if (mounted) _notice(context, success ? 'Product created and shared with Admin.' : widget.state.error ?? 'Unable to create product.');
  }
}
