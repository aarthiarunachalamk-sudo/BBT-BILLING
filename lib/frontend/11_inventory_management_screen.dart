import 'package:flutter/material.dart';
import '../state/billing_state.dart';
import '../widgets/custom_widgets.dart';

class InventoryManagementScreen extends StatelessWidget {
  final BillingState state;

  const InventoryManagementScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Inventory Management',
        showBackButton: false,
        actions: [
          IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                    hintText: 'Search materials by name or SKU',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF0F52BA)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Metric Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniMetricCard('Total Materials', '124', const Color(0xFF1E293B)),
                          _buildMiniMetricCard('In Stock', '110', const Color(0xFF16A34A)),
                          _buildMiniMetricCard('Low Stock', '11', const Color(0xFFF97316)),
                          _buildMiniMetricCard('Out of Stock', '3', const Color(0xFFEF4444)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Inventory Value Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Inventory Value',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            Text(
                              '₹18,42,600.00',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Operations Grid
                      Row(
                        children: [
                          _buildOpButton(Icons.add, 'Stock In'),
                          _buildOpButton(Icons.remove, 'Stock Out'),
                          _buildOpButton(Icons.tune, 'Adjustment'),
                          _buildOpButton(Icons.history, 'History'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Materials List Header
                      const Text(
                        'Material List',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 10),

                      // Material Table Container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            // Table Columns
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: Text('Material', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(flex: 1, child: Text('Stock', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                ],
                              ),
                            ),
                            // Router Row
                            _buildMaterialRow('Router', 'RTR-001', state.routerStock, state.routerStock > 5 ? 'In Stock' : 'Low Stock'),
                            // Cable Row
                            _buildMaterialRow('Network Cable (Cat6)', 'NCB-CS', state.networkCableStock, 'In Stock'),
                            // Switch Row
                            _buildMaterialRow('Switch 24 Port', 'SW-024', state.switchStock, 'Low Stock'),
                            // Panel Row
                            _buildMaterialRow('Patch Panel 24 Port', 'PP-024', state.patchPanelStock, 'Out of Stock'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        activeIndex: 10, // Maps to inventory tab
        onTapItem: (index) => state.setScreenIndex(index),
      ),
    );
  }

  Widget _buildMiniMetricCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              val,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpButton(IconData icon, String title) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475569)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialRow(String name, String sku, int qty, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              sku,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: StatusPill(text: status, type: status),
            ),
          ),
        ],
      ),
    );
  }
}
