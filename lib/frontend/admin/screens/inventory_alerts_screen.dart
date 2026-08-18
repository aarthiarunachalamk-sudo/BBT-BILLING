part of '../admin_screens.dart';

class InventoryAlertsScreen extends StatefulWidget {
  const InventoryAlertsScreen(this.state, {super.key});
  final AdminState state;

  @override
  State<InventoryAlertsScreen> createState() => _InventoryAlertsScreenState();
}

class _InventoryAlertsScreenState extends State<InventoryAlertsScreen> {
  int? selectedItemId;

  List<Map<String, dynamic>> get filtered {
    final now = DateTime.now();
    final expiryLimit = now.add(const Duration(days: 30));
    return widget.state.products.where((product) {
      final status = product['stock_status']?.toString();
      if (widget.state.inventoryFilter == 'Out of Stock') {
        return status == 'out_of_stock';
      }
      if (widget.state.inventoryFilter == 'Expiring') {
        final expiry = DateTime.tryParse(
          product['expiry_date']?.toString() ?? '',
        );
        return expiry != null && !expiry.isAfter(expiryLimit);
      }
      return status == 'low_stock';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    if (items.isNotEmpty &&
        !items.any((item) => item['id'] == selectedItemId)) {
      selectedItemId = items.first['id'] as int?;
    }

    return _AdminPage(
      state: widget.state,
      title: 'Inventory Alerts',
      back: 4,
      bottom: false,
      child: Column(
        children: [
          Row(
            children: ['Low Stock', 'Expiring', 'Out of Stock']
                .map(
                  (filter) => Expanded(
                    child: InkWell(
                      onTap: () {
                        widget.state.setInventoryFilter(filter);
                        setState(() => selectedItemId = null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: widget.state.inventoryFilter == filter
                                  ? blue
                                  : line,
                              width: widget.state.inventoryFilter == filter
                                  ? 2
                                  : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          filter,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.state.inventoryFilter == filter
                                ? blue
                                : muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 16, 14, 0),
            child: _TableHeader(['Item', 'Current', 'Min. Stock', 'Expiry']),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyState(
                    'No inventory alerts for this filter.',
                    icon: Icons.inventory_outlined,
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: items
                        .map(
                          (item) => InkWell(
                            onTap: () => setState(
                              () => selectedItemId = item['id'] as int?,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedItemId == item['id']
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: selectedItemId == item['id']
                                      ? blue
                                      : muted,
                                ),
                                Expanded(
                                  child: _TableRow([
                                    item['name']?.toString() ?? '',
                                    item['stock_quantity']?.toString() ?? '0',
                                    item['reorder_level']?.toString() ?? '0',
                                    _dateText(item['expiry_date']),
                                  ], highlight: true),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryAction(
                    'Create Reorder',
                    onPressed: () => _reorder(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryAction(
                    'Adjust Stock',
                    outlined: true,
                    onPressed: () => _showStockDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reorder(BuildContext context) async {
    if (selectedItemId == null) {
      showNotice(context, 'Select a product first.');
      return;
    }
    try {
      await widget.state.createReorder(selectedItemId!);
      if (context.mounted) showNotice(context, 'Purchase order created');
    } catch (error) {
      if (context.mounted) showNotice(context, error.toString());
    }
  }

  Future<void> _showStockDialog(BuildContext context) async {
    if (selectedItemId == null) {
      showNotice(context, 'Select a product first.');
      return;
    }
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Signed quantity',
            hintText: 'Example: 5 or -2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value == 0) return;
              try {
                await widget.state.adjustStock(selectedItemId!, value);
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
    controller.dispose();
  }
}
