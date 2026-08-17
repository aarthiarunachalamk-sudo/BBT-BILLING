import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final double unitPrice;
  int quantity;
  final int? inStock; // null if service, otherwise remaining stock
  final String sku;

  CartItem({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.inStock,
    required this.sku,
  });

  double get amount => unitPrice * quantity;
}

class MaterialItem {
  final String name;
  final String sku;
  int stock;
  final String status; // 'In Stock', 'Low Stock', 'Out of Stock'

  MaterialItem({
    required this.name,
    required this.sku,
    required this.stock,
    required this.status,
  });
}

class BillingState extends ChangeNotifier {
  // Global Navigation
  int _activeScreenIndex = 0;
  int get activeScreenIndex => _activeScreenIndex;

  void setScreenIndex(int index) {
    _activeScreenIndex = index;
    notifyListeners();
  }

  // Role Selection
  String _selectedRole = 'Sales';
  String get selectedRole => _selectedRole;

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  // Client Details
  String clientName = 'Acme Solutions Pvt. Ltd.';
  String contactPerson = 'Mr. Ankit Verma';
  String whatsappMobile = '+91 98765 43210';
  String email = 'ankit.verma@acmesolutions.com';
  String gstin = '27AABCA1234B1Z5';
  String billingAddress = 'Acme Solutions Pvt. Ltd.\nS01, Skyline Tower, Andheri East,\nMumbai - 400069, Maharashtra, India';
  double outstandingAmount = 512430.0;

  void updateClient({
    required String name,
    required String contact,
    required String mobile,
    required String emailId,
    required String gst,
    required String address,
  }) {
    clientName = name;
    contactPerson = contact;
    whatsappMobile = mobile;
    email = emailId;
    gstin = gst;
    billingAddress = address;
    notifyListeners();
  }

  // Cart / Items
  final List<CartItem> cartItems = [
    CartItem(name: 'Cloud Support (Monthly)', unitPrice: 15000.0, quantity: 3, sku: 'CS-MON'),
    CartItem(name: 'Router', unitPrice: 8500.0, quantity: 1, sku: 'RTR-001', inStock: 24),
    CartItem(name: 'Network Cable (Cat6)', unitPrice: 45.0, quantity: 100, sku: 'NCB-CS', inStock: 156),
  ];

  void updateQuantity(int index, int newQty) {
    if (index >= 0 && index < cartItems.length) {
      if (newQty <= 0) {
        cartItems.removeAt(index);
      } else {
        cartItems[index].quantity = newQty;
      }
      notifyListeners();
    }
  }

  void addCartItem(CartItem item) {
    cartItems.add(item);
    notifyListeners();
  }

  // Calculations
  double get subtotal {
    double sum = 0;
    for (var item in cartItems) {
      sum += item.amount;
    }
    return sum;
  }

  double discountPercent = 6.0;
  double get discountAmount => subtotal * (discountPercent / 100.0);
  double get taxableAmount => subtotal - discountAmount;
  double get cgst => taxableAmount * 0.09;
  double get sgst => taxableAmount * 0.09;
  double get totalInvoiceAmount => taxableAmount + cgst + sgst;

  // Invoice Centre / Approvals
  String approvalStatus = 'Pending'; // 'Pending', 'Approved', 'Rejected'
  String invoiceId = 'INV-2026-00128';
  String invoiceDate = '12 May 2026';
  String invoiceDueDate = '27 May 2026 (15 Days)';

  void setApprovalStatus(String status) {
    approvalStatus = status;
    notifyListeners();
  }

  // WhatsApp Billing Chat Simulator
  bool isReminderSent = false;
  final List<Map<String, dynamic>> whatsappMessages = [
    {
      'sender': 'app',
      'text': 'Hello Mr. Ankit Verma,\n\nPlease find attached invoice INV-2026-00128 for ₹3,04,968.00.\n\nYou can view and pay securely using the link below:\nPay Securely: https://pay.sb360.in/pay/INV-2026-00128\n\nThank you for your business!',
      'time': '10:25 AM',
      'isDoc': false,
      'status': 'read', // 'sent', 'delivered', 'read'
    },
    {
      'sender': 'app',
      'text': 'INV-2026-00128.pdf\n128 KB • PDF',
      'time': '10:25 AM',
      'isDoc': true,
      'status': 'read',
    }
  ];

  void sendWhatsAppMessage(String text) {
    whatsappMessages.add({
      'sender': 'app',
      'text': text,
      'time': '10:30 AM',
      'isDoc': false,
      'status': 'sent',
    });
    notifyListeners();
  }

  void sendReminder() {
    isReminderSent = true;
    whatsappMessages.add({
      'sender': 'app',
      'text': '⚠️ Reminder: Invoice INV-2026-00128 payment of ₹3,04,968.00 is due on 27 May 2026. Please pay to avoid service disruption.',
      'time': '10:32 AM',
      'isDoc': false,
      'status': 'sent',
    });
    notifyListeners();
  }

  // Payment Collection
  String paymentType = 'Full'; // 'Full', 'Advance', 'Partial'
  String paymentMethod = 'UPI'; // 'UPI', 'Bank', 'Card', 'Cash'
  String transactionUtr = 'SB360UPI1205261025';
  String paymentProofFile = 'payment_proof_120526.jpg';
  bool isPaid = false;

  void confirmPayment() {
    isPaid = true;
    // Perform Stock Updates
    routerStock = 23;
    networkCableStock = 153;
    notifyListeners();
  }

  // Inventory Stocks (changes on payment)
  int routerStock = 24;
  int networkCableStock = 156;
  int switchStock = 5;
  int patchPanelStock = 0;

  void updateStock(String sku, int quantity) {
    if (sku == 'RTR-001') {
      routerStock = quantity;
    } else if (sku == 'NCB-CS') {
      networkCableStock = quantity;
    } else if (sku == 'SW-024') {
      switchStock = quantity;
    } else if (sku == 'PP-024') {
      patchPanelStock = quantity;
    }
    notifyListeners();
  }
}
