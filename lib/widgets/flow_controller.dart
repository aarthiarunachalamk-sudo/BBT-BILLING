import 'package:flutter/material.dart';

class FlowControllerPanel extends StatelessWidget {
  final int activeIndex;
  final Function(int) onSelectScreen;

  const FlowControllerPanel({
    super.key,
    required this.activeIndex,
    required this.onSelectScreen,
  });

  static const List<Map<String, dynamic>> screensInfo = [
    {'num': '01', 'title': 'Login', 'desc': 'Role Selection & Entry', 'icon': Icons.login},
    {'num': '02', 'title': 'Dashboard', 'desc': 'Executive Stats & Actions', 'icon': Icons.dashboard},
    {'num': '03', 'title': 'Client Details', 'desc': 'Existing & New Info', 'icon': Icons.person},
    {'num': '04', 'title': 'Services & Materials', 'desc': 'Line Items & Quantities', 'icon': Icons.shopping_bag},
    {'num': '05', 'title': 'Smart Quotation', 'desc': 'Tax, Rates & Delivery', 'icon': Icons.description},
    {'num': '06', 'title': 'Discount Approval', 'desc': 'Manager Timeline & Override', 'icon': Icons.rate_review},
    {'num': '07', 'title': 'Invoice Centre', 'desc': 'Billed Invoices & Actions', 'icon': Icons.receipt_long},
    {'num': '08', 'title': 'WhatsApp Billing', 'desc': 'PDF Share & Reminders', 'icon': Icons.message},
    {'num': '09', 'title': 'Payment Collection', 'desc': 'UTR & Payment Verification', 'icon': Icons.payment},
    {'num': '10', 'title': 'Payment Success', 'desc': 'Live Stock Deductions', 'icon': Icons.check_circle},
    {'num': '11', 'title': 'Inventory Management', 'desc': 'Stock Control & Adjustment', 'icon': Icons.inventory},
    {'num': '12', 'title': 'Admin Materials', 'desc': 'Safe Product Control', 'icon': Icons.admin_panel_settings},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Control Panel Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF0F52BA), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interactive Flow',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Click to preview or step through',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Screens List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: screensInfo.length,
              itemBuilder: (context, index) {
                final screen = screensInfo[index];
                final isActive = index == activeIndex;
                final isCompleted = index < activeIndex;

                return InkWell(
                  onTap: () => onSelectScreen(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Screen index circle
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFF3B82F6)
                                : isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF1F5F9),
                          ),
                          child: Center(
                            child: isCompleted && !isActive
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : Text(
                                    screen['num'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Screen title and description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                screen['title'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                  color: isActive
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFF334155),
                                ),
                              ),
                              Text(
                                screen['desc'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isActive
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          screen['icon'],
                          size: 18,
                          color: isActive
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
