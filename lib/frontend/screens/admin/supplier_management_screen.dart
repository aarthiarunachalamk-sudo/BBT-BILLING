part of 'admin_screens.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen(this.state, {super.key});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final filtered = state.suppliers.where((supplier) {
      final searchable = [
        supplier['name'],
        supplier['gstin'],
        supplier['phone'],
        supplier['email'],
      ].join(' ').toLowerCase();
      return searchable.contains(state.supplierQuery);
    }).toList();
    return _AdminPage(
      state: state,
      title: 'Supplier Management',
      back: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBox(
              'Search suppliers',
              onChanged: state.setSupplierQuery,
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState(
                    'No suppliers found.',
                    icon: Icons.local_shipping_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final supplier = filtered[index];
                      final active = supplier['is_active'] == true;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 5),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF2FF),
                          child: Icon(Icons.storefront, color: blue),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplier['name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 9,
                                color: active ? green : red,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'GSTIN: ${supplier['gstin'] ?? '—'}\n'
                          'Phone: ${supplier['phone'] ?? '—'}\n'
                          'Email: ${supplier['email'] ?? '—'}',
                          style: const TextStyle(fontSize: 9, height: 1.5),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryAction(
                    'Add Supplier',
                    icon: Icons.add,
                    onPressed: () => _showAddSupplierDialog(context, state),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: PrimaryAction(
                    'View Orders',
                    outlined: true,
                    onPressed: () => state.go(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddSupplierDialog(
  BuildContext context,
  AdminState state,
) async {
  final name = TextEditingController();
  final gstin = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add Supplier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Supplier name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: gstin,
              decoration: const InputDecoration(labelText: 'GSTIN'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              await state.createSupplier({
                'name': name.text.trim(),
                'gstin': gstin.text.trim(),
                'phone': phone.text.trim(),
                'email': email.text.trim(),
                'is_active': true,
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } catch (error) {
              if (context.mounted) showNotice(context, error.toString());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  name.dispose();
  gstin.dispose();
  phone.dispose();
  email.dispose();
}
