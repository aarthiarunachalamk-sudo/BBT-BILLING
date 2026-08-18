part of '../admin_screens.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen(this.state, {super.key});
  final AdminState state;
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int gst = 12;
  @override
  Widget build(BuildContext context) => _AdminPage(
    state: widget.state,
    title: 'Add Product',
    back: 4,
    bottom: false,
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: 'Sunfeast Marie Biscuit 250g',
                decoration: const InputDecoration(labelText: 'Product Name *'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Barcode / SKU',
                  hintText: 'Scan or enter barcode / SKU',
                  suffixIcon: Icon(Icons.qr_code_scanner, color: blue),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: 'Snacks',
                decoration: const InputDecoration(labelText: 'Category *'),
                items: ['Snacks', 'Grocery & Staples', 'Beverages']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (_) {},
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '40.00',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price (â‚¹)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: '50.00',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'MRP (â‚¹)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: '45.00',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (â‚¹) *',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GST Slab *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [0, 5, 12, 18, 28]
                    .map(
                      (v) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: ChoiceChip(
                            label: Text(
                              '$v%',
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: gst == v,
                            onSelected: (_) => setState(() => gst = v),
                            selectedColor: blue,
                            labelStyle: TextStyle(
                              color: gst == v ? Colors.white : ink,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: 'Pack',
                      decoration: const InputDecoration(labelText: 'Unit *'),
                      items: ['Pack', 'Piece', 'Kg']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: '20',
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryAction(
            'Save Product',
            onPressed: () async {
              try {
                await widget.state.createDemoProduct(gst: gst);
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
