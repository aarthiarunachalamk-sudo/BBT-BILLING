import 'package:flutter/material.dart';
import 'state/billing_state.dart';
import 'widgets/device_frame.dart';
import 'widgets/flow_controller.dart';

// Screens
import 'frontend/splash_screen.dart';
import 'frontend/01_login_screen.dart';
import 'frontend/02_dashboard_screen.dart';
import 'frontend/03_client_details_screen.dart';
import 'frontend/04_services_materials_screen.dart';
import 'frontend/05_smart_quotation_screen.dart';
import 'frontend/06_discount_approval_screen.dart';
import 'frontend/07_invoice_centre_screen.dart';
import 'frontend/08_whatsapp_billing_screen.dart';
import 'frontend/09_payment_collection_screen.dart';
import 'frontend/10_payment_success_screen.dart';
import 'frontend/11_inventory_management_screen.dart';
import 'frontend/12_admin_material_management_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Billing 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F52BA),
          primary: const Color(0xFF0F52BA),
          secondary: const Color(0xFF10B981),
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(destination: MainShell()),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final BillingState _billingState = BillingState();

  @override
  void initState() {
    super.initState();
    _billingState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _billingState.removeListener(_onStateChange);
    _billingState.dispose();
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  Widget _getActiveScreen(int index) {
    switch (index) {
      case 0:
        return LoginScreen(state: _billingState);
      case 1:
        return DashboardScreen(state: _billingState);
      case 2:
        return ClientDetailsScreen(state: _billingState);
      case 3:
        return ServicesMaterialsScreen(state: _billingState);
      case 4:
        return SmartQuotationScreen(state: _billingState);
      case 5:
        return DiscountApprovalScreen(state: _billingState);
      case 6:
        return InvoiceCentreScreen(state: _billingState);
      case 7:
        return WhatsAppBillingScreen(state: _billingState);
      case 8:
        return PaymentCollectionScreen(state: _billingState);
      case 9:
        return PaymentSuccessScreen(state: _billingState);
      case 10:
        return InventoryManagementScreen(state: _billingState);
      case 11:
        return AdminMaterialManagementScreen(state: _billingState);
      default:
        return LoginScreen(state: _billingState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            return Row(
              children: [
                // Demo Center Panel
                Expanded(
                  child: Column(
                    children: [
                      // Branding & Subtitle Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'SMART BILLING 360',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F52BA),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '—   MOBILE APPLICATION UI',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Billing  •  WhatsApp  •  Payments  •  Inventory  •  Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // Quick Role Indicator Pills
                            Row(
                              children: [
                                _buildIndicatorPill(
                                  'Sales',
                                  const Color(0xFF3B82F6),
                                  Icons.person,
                                ),
                                const SizedBox(width: 8),
                                _buildIndicatorPill(
                                  'Accountant',
                                  const Color(0xFF7C3AED),
                                  Icons.account_balance,
                                ),
                                const SizedBox(width: 8),
                                _buildIndicatorPill(
                                  'Inventory',
                                  const Color(0xFFF59E0B),
                                  Icons.inventory,
                                ),
                                const SizedBox(width: 8),
                                _buildIndicatorPill(
                                  'Admin',
                                  const Color(0xFFEF4444),
                                  Icons.admin_panel_settings,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Simulated Phone preview area
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: DeviceFrame(
                                child: _getActiveScreen(
                                  _billingState.activeScreenIndex,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right Flow Selection Controller
                FlowControllerPanel(
                  activeIndex: _billingState.activeScreenIndex,
                  onSelectScreen: (index) {
                    _billingState.setScreenIndex(index);
                  },
                ),
              ],
            );
          } else {
            // Mobile Responsive View (Full Screen with Quick Flow Switcher Overlay)
            return Stack(
              children: [
                _getActiveScreen(_billingState.activeScreenIndex),
                // Mini Float Overlay to switch screens during testing
                Positioned(
                  right: 16,
                  bottom: 80,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF0F52BA),
                    child: const Icon(Icons.swap_calls, color: Colors.white),
                    onPressed: () {
                      _showScreenSelectorBottomSheet(context);
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildIndicatorPill(String title, Color color, IconData icon) {
    final isSelected = _billingState.selectedRole == title;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? color : const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  void _showScreenSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Switch Screen Flow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: FlowControllerPanel.screensInfo.length,
                  itemBuilder: (context, index) {
                    final item = FlowControllerPanel.screensInfo[index];
                    final isActive = index == _billingState.activeScreenIndex;

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: isActive
                            ? const Color(0xFF0F52BA)
                            : const Color(0xFFE2E8F0),
                        child: Text(
                          item['num'],
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item['title'],
                        style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Icon(
                        item['icon'],
                        size: 16,
                        color: isActive ? const Color(0xFF0F52BA) : Colors.grey,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _billingState.setScreenIndex(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
