import 'package:flutter/material.dart';
import '../state/billing_state.dart';
import '../widgets/custom_widgets.dart';

class AdminMaterialManagementScreen extends StatefulWidget {
  final BillingState state;

  const AdminMaterialManagementScreen({super.key, required this.state});

  @override
  State<AdminMaterialManagementScreen> createState() => _AdminMaterialManagementScreenState();
}

class _AdminMaterialManagementScreenState extends State<AdminMaterialManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool routerActive = true;
  bool cableActive = true;
  bool switchActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = widget.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: Container(
          color: const Color(0xFF0F52BA),
          padding: const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 12),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  onPressed: () => billingState.setScreenIndex(1), // Back to Dashboard
                ),
                const Expanded(
                  child: Text(
                    'Admin Material Mgmt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Admin Only',
                    style: TextStyle(color: Color(0xFF6D28D9), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: billingState,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Admin Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF0F52BA),
                  labelColor: const Color(0xFF0F52BA),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: 'Materials'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Suppliers'),
                  ],
                ),
              ),

              // Tab Content Area
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMaterialsTab(billingState),
                    const Center(child: Text('Categories Configuration', style: TextStyle(color: Color(0xFF64748B)))),
                    const Center(child: Text('Suppliers List & Details', style: TextStyle(color: Color(0xFF64748B)))),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        activeIndex: 11, // Maps to Admin tab
        onTapItem: (index) => billingState.setScreenIndex(index),
      ),
    );
  }

  Widget _buildMaterialsTab(BillingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section title & Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Materials',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Material', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F52BA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Router Row Card
          _buildAdminMaterialCard(
            name: 'Router',
            sku: 'RTR-001',
            qty: state.routerStock,
            isActive: routerActive,
            onToggle: (val) {
              setState(() {
                routerActive = val;
              });
            },
          ),

          // Cable Row Card
          _buildAdminMaterialCard(
            name: 'Network Cable (Cat6)',
            sku: 'NCB-CS',
            qty: state.networkCableStock,
            isActive: cableActive,
            onToggle: (val) {
              setState(() {
                cableActive = val;
              });
            },
          ),

          // Switch Row Card
          _buildAdminMaterialCard(
            name: 'Switch 24 Port',
            sku: 'SW-024',
            qty: state.switchStock,
            isActive: switchActive,
            onToggle: (val) {
              setState(() {
                switchActive = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // Safe Delete Alert / Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This item has been used in billed invoices. Deactivate instead of deleting to maintain data integrity.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Row
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  text: 'Deactivate',
                  onPressed: () {
                    setState(() {
                      routerActive = false;
                      cableActive = false;
                      switchActive = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMaterialCard({
    required String name,
    required String sku,
    required int qty,
    required bool isActive,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Material Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: $sku  •  In Stock: $qty',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Actions: Toggle, Edit, Delete
          Row(
            children: [
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeColor: const Color(0xFF0F52BA),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                onPressed: () {},
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                onPressed: () {},
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          )
        ],
      ),
    );
  }
}
