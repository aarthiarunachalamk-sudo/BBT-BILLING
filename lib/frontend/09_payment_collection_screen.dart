import 'package:flutter/material.dart';
import '../state/billing_state.dart';
import '../widgets/custom_widgets.dart';

class PaymentCollectionScreen extends StatefulWidget {
  final BillingState state;

  const PaymentCollectionScreen({super.key, required this.state});

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  @override
  Widget build(BuildContext context) {
    final billingState = widget.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Payment Collection',
        onBackPressed: () => billingState.setScreenIndex(7), // Back to WhatsApp Chat
      ),
      body: ListenableBuilder(
        listenable: billingState,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment Type Header
                const Text(
                  'Payment Type',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                // Payment Type Selector
                Row(
                  children: [
                    _buildPaymentTypeBtn('Full', billingState),
                    const SizedBox(width: 8),
                    _buildPaymentTypeBtn('Advance', billingState),
                    const SizedBox(width: 8),
                    _buildPaymentTypeBtn('Partial', billingState),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount to Collect Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Amount to Collect',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '₹3,04,968.00',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Method Header
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                // Payment Method Grid
                Row(
                  children: [
                    _buildPaymentMethodCell('UPI', Icons.phone_iphone, billingState),
                    _buildPaymentMethodCell('Bank Transfer', Icons.account_balance, billingState),
                    _buildPaymentMethodCell('Card', Icons.credit_card, billingState),
                    _buildPaymentMethodCell('Cash', Icons.payments, billingState),
                  ],
                ),
                const SizedBox(height: 20),

                // Transaction Reference/UTR
                CustomTextField(
                  label: 'Transaction Reference / UTR',
                  initialValue: billingState.transactionUtr,
                  onChanged: (val) => billingState.transactionUtr = val,
                ),
                const SizedBox(height: 20),

                // Uploaded Proof
                const Text(
                  'Upload Payment Proof',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              billingState.paymentProofFile,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const Text(
                              '128 KB',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFEF4444), size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Confirm Payment
                PrimaryButton(
                  text: 'Confirm Payment',
                  onPressed: () {
                    billingState.confirmPayment();
                    billingState.setScreenIndex(9); // Go to Payment Success (10)
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentTypeBtn(String type, BillingState billingState) {
    final isSelected = billingState.paymentType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            billingState.paymentType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF15803D) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCell(String method, IconData icon, BillingState billingState) {
    final isSelected = billingState.paymentMethod == method;
    final primaryColor = const Color(0xFF0F52BA);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            billingState.paymentMethod = method;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? primaryColor : const Color(0xFF64748B), size: 20),
              const SizedBox(height: 6),
              Text(
                method,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
