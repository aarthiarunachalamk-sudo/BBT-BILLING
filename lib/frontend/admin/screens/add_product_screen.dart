part of '../admin_screens.dart';

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
  final stock = TextEditingController();
  final reorderLevel = TextEditingController();
  final expiryDate = TextEditingController();
  int gst = 0;
  int? categoryId;
  String? unit;

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
    stock.dispose();
    reorderLevel.dispose();
    expiryDate.dispose();
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 52,
                          color: muted,
                        ),
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
                            onPressed: () async {
                              await _showAddCategoryDialog(
                                context,
                                widget.state,
                              );
                              if (mounted &&
                                  widget.state.categories.isNotEmpty) {
                                setState(() {
                                  categoryId =
                                      widget.state.categories.first['id']
                                          as int?;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: name,
                        validator: requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: sku,
                        validator: requiredText,
                        decoration: const InputDecoration(
                          labelText: 'Barcode / SKU *',
                          suffixIcon: Icon(Icons.qr_code_scanner, color: blue),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        initialValue: categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                        ),
                        items: widget.state.categories
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: category['id'] as int,
                                child: Text(category['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => categoryId = value),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: purchasePrice,
                              validator: requiredText,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Purchase Price (₹) *',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: sellingPrice,
                              validator: requiredText,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (₹) *',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: expiryDate,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date (optional)',
                          hintText: 'YYYY-MM-DD',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GST Slab *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: const InputDecoration(labelText: 'Unit *'),
                        items: const [
                          DropdownMenuItem(value: 'Pack', child: Text('Pack')),
                          DropdownMenuItem(
                            value: 'Piece',
                            child: Text('Piece'),
                          ),
                          DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                          DropdownMenuItem(
                            value: 'Litre',
                            child: Text('Litre'),
                          ),
                        ],
                        onChanged: (value) => setState(() => unit = value),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stock,
                              validator: requiredText,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Opening Stock *',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: reorderLevel,
                              validator: requiredText,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Minimum Stock *',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        if (widget.state.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: PrimaryAction(
              'Save Product',
              onPressed: () async {
                if (formKey.currentState?.validate() != true ||
                    categoryId == null) {
                  return;
                }
                try {
                  await widget.state.createProduct({
                    'item_type': 'material',
                    'name': name.text.trim(),
                    'sku': sku.text.trim(),
                    'category': categoryId,
                    'unit': unit,
                    'purchase_price': purchasePrice.text.trim(),
                    'selling_price': sellingPrice.text.trim(),
                    'tax_percent': gst.toString(),
                    'stock_quantity': int.tryParse(stock.text.trim()) ?? 0,
                    'reorder_level':
                        int.tryParse(reorderLevel.text.trim()) ?? 0,
                    'expiry_date': expiryDate.text.trim().isEmpty
                        ? null
                        : expiryDate.text.trim(),
                    'is_active': true,
                  });
                  if (context.mounted) {
                    showNotice(context, 'Product saved successfully');
                    widget.state.go(4);
                  }
                } catch (error) {
                  if (context.mounted) showNotice(context, error.toString());
                }
              },
            ),
          ),
      ],
    ),
  );
}
