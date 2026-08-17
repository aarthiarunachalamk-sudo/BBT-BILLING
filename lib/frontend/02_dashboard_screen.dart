import 'package:flutter/material.dart';
import '../state/billing_state.dart';
import '../widgets/custom_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final BillingState state;

  const DashboardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: const Color(0xFF0F52BA),
          padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Hello, Rohit Sharma',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${state.selectedRole} Executive',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grid of Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: "Today's Sales",
                    value: "₹3,04,968",
                    color: const Color(0xFFDCFCE7),
                    valueColor: const Color(0xFF15803D),
                    label: "+12.5% vs yesterday",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: "Outstanding",
                    value: "₹5,12,430",
                    color: const Color(0xFFF3E8FF),
                    valueColor: const Color(0xFF7E22CE),
                    label: "Overdue from 4 clients",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAlertCard(
                    context,
                    title: "Pending Approvals",
                    count: "8",
                    color: const Color(0xFFFEE2E2),
                    countColor: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAlertCard(
                    context,
                    title: "Low Stock Items",
                    count: "11",
                    color: const Color(0xFFFFEDD5),
                    countColor: const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(
                  context,
                  label: "New Bill",
                  icon: Icons.add_shopping_cart,
                  color: const Color(0xFF3B82F6),
                  onTap: () => state.setScreenIndex(2), // Client Details
                ),
                _buildQuickAction(
                  context,
                  label: "WhatsApp Bill",
                  icon: Icons.message,
                  color: const Color(0xFF10B981),
                  onTap: () => state.setScreenIndex(7), // WhatsApp Screen (08)
                ),
                _buildQuickAction(
                  context,
                  label: "Inventory",
                  icon: Icons.inventory_2,
                  color: const Color(0xFFF59E0B),
                  onTap: () => state.setScreenIndex(10), // Inventory Screen (11)
                ),
                _buildQuickAction(
                  context,
                  label: "Admin",
                  icon: Icons.admin_panel_settings,
                  color: const Color(0xFFEF4444),
                  onTap: () => state.setScreenIndex(11), // Admin Screen (12)
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F52BA),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Transaction List Items
            _buildTransactionItem(
              id: 'INV-2026-00128',
              client: 'Acme Solutions Pvt. Ltd.',
              amount: '₹3,04,968',
              status: 'Paid',
              statusType: 'paid',
            ),
            _buildTransactionItem(
              id: 'INV-2026-00127',
              client: 'TechNova India Pvt. Ltd.',
              amount: '₹1,25,800',
              status: 'Paid',
              statusType: 'paid',
            ),
            _buildTransactionItem(
              id: 'INV-2026-00126',
              client: 'Global Systems',
              amount: '₹85,750',
              status: 'Unpaid',
              statusType: 'unpaid',
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        activeIndex: 1,
        onTapItem: (index) => state.setScreenIndex(index),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required Color color,
      required Color valueColor,
      required String label}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context,
      {required String title, required String count, required Color color, required Color countColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: countColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context,
      {required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String id,
    required String client,
    required String amount,
    required String status,
    required String statusType,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                id,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                client,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              StatusPill(text: status, type: statusType),
            ],
          )
        ],
      ),
    );
  }
}
