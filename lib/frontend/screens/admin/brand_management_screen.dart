part of 'admin_screens.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen(this.state, {super.key});

  final AdminState state;

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final brands = widget.state.brands.where((brand) {
      final text =
          '${brand['name']} ${brand['manufacturer']} ${brand['country']}'
              .toLowerCase();
      return text.contains(query);
    }).toList();
    return _AdminPage(
      state: widget.state,
      title: 'Brand Management',
      back: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: SearchBox(
              'Search brand or manufacturer',
              onChanged: (value) => setState(() => query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: brands.isEmpty
                ? const _EmptyState(
                    'No brands found. Add your first brand.',
                    icon: Icons.branding_watermark_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
                    itemCount: brands.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      final active = brand['is_active'] == true;
                      return SectionCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFEAF2FF),
                              child: Text(
                                brand['name'].toString().isEmpty
                                    ? '?'
                                    : brand['name'].toString()[0].toUpperCase(),
                                style: const TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    brand['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${brand['manufacturer']?.toString().isNotEmpty == true ? brand['manufacturer'] : 'Independent brand'} • ${brand['product_count'] ?? 0} products',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                  if (brand['country']?.toString().isNotEmpty ==
                                      true)
                                    Text(
                                      brand['country'].toString(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: muted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Switch(
                              value: active,
                              onChanged: (value) async {
                                try {
                                  await widget.state.toggleBrand(brand, value);
                                } catch (error) {
                                  if (context.mounted)
                                    showNotice(context, error.toString());
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: PrimaryAction(
              'Add Brand',
              icon: Icons.add,
              onPressed: () => showDialog<void>(
                context: context,
                useSafeArea: false,
                builder: (_) => _AddBrandDialog(state: widget.state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBrandDialog extends StatefulWidget {
  const _AddBrandDialog({required this.state});

  final AdminState state;

  @override
  State<_AddBrandDialog> createState() => _AddBrandDialogState();
}

class _AddBrandDialogState extends State<_AddBrandDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final manufacturer = TextEditingController();
  final country = TextEditingController(text: 'India');
  final website = TextEditingController();
  final email = TextEditingController();
  final description = TextEditingController();
  bool saving = false;
  String? errorText;

  @override
  void dispose() {
    name.dispose();
    manufacturer.dispose();
    country.dispose();
    website.dispose();
    email.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Dialog(
      insetPadding: mobile ? EdgeInsets.zero : const EdgeInsets.all(28),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mobile ? 0 : 20),
      ),
      child: SizedBox(
        width: mobile ? double.infinity : 560,
        height: mobile ? double.infinity : 700,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Add Brand'),
            actions: [
              IconButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _field(
                  name,
                  'Brand name *',
                  Icons.branding_watermark_outlined,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                _field(
                  manufacturer,
                  'Manufacturer / company',
                  Icons.factory_outlined,
                ),
                _field(country, 'Country', Icons.public_outlined),
                _field(
                  website,
                  'Website',
                  Icons.language_outlined,
                  keyboardType: TextInputType.url,
                ),
                _field(
                  email,
                  'Contact email',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  description,
                  'Description',
                  Icons.notes_outlined,
                  maxLines: 3,
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorText!, style: const TextStyle(color: red)),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryAction(
                saving ? 'Saving...' : 'Save Brand',
                icon: saving ? null : Icons.check,
                onPressed: saving ? null : _save,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      saving = true;
      errorText = null;
    });
    try {
      await widget.state.createBrand({
        'name': name.text.trim(),
        'manufacturer': manufacturer.text.trim(),
        'country': country.text.trim(),
        'website': website.text.trim(),
        'contact_email': email.text.trim(),
        'description': description.text.trim(),
        'is_active': true,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        saving = false;
        errorText = error.toString();
      });
    }
  }
}
