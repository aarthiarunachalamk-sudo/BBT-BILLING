import 'package:flutter/material.dart';
import '../state/billing_state.dart';
import '../widgets/custom_widgets.dart';

class ClientDetailsScreen extends StatefulWidget {
  final BillingState state;

  const ClientDetailsScreen({super.key, required this.state});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: CustomAppBar(
        title: 'Client Details',
        onBackPressed: () => billingState.setScreenIndex(1), // Back to Dashboard
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Custom Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF0F52BA),
              labelColor: const Color(0xFF0F52BA),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Existing Client'),
                Tab(text: 'Add New'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExistingClientTab(billingState),
                _buildAddNewClientTab(billingState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingClientTab(BillingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Client Dropdown Mock
          const Text(
            'Client Name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.clientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Contact Person',
            initialValue: state.contactPerson,
            onChanged: (val) => state.contactPerson = val,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'WhatsApp Mobile',
            initialValue: state.whatsappMobile,
            keyboardType: TextInputType.phone,
            onChanged: (val) => state.whatsappMobile = val,
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(
                Icons.phone_android,
                color: Color(0xFF22C55E),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Email',
            initialValue: state.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => state.email = val,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'GSTIN',
            initialValue: state.gstin,
            onChanged: (val) => state.gstin = val,
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Billing Address',
            initialValue: state.billingAddress,
            onChanged: (val) => state.billingAddress = val,
          ),
          const SizedBox(height: 20),

          // Outstanding Alert Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFE11D48), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Outstanding Amount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBE123C),
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${state.outstandingAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            text: 'Save & Continue',
            onPressed: () {
              state.setScreenIndex(3); // Go to Services & Materials
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewClientTab(BillingState state) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          CustomTextField(label: 'Client Name'),
          SizedBox(height: 16),
          CustomTextField(label: 'Contact Person'),
          SizedBox(height: 16),
          CustomTextField(label: 'WhatsApp Mobile'),
          SizedBox(height: 16),
          CustomTextField(label: 'Email'),
          SizedBox(height: 16),
          CustomTextField(label: 'GSTIN'),
          SizedBox(height: 16),
          CustomTextField(label: 'Billing Address'),
        ],
      ),
    );
  }
}
