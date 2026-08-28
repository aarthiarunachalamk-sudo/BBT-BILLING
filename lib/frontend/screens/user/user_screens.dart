import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../widgets/product_image_widget.dart';
import '../../../widgets/barcode_scanner_screen.dart';
import '../../../services/barcode_label_service.dart';

import 'user_api.dart';
import 'user_models.dart';
import 'user_state.dart';
import 'user_widgets.dart';
import 'invoice_pdf_service.dart';

part 'staff_login_screen.dart';
part 'user_password_reset_screen.dart';
part 'user_verification_screen.dart';
part 'user_dashboard_screen.dart';
part 'inventory_categories_screen.dart';
part 'user_add_product_screen.dart';
part 'current_stock_screen.dart';
part 'shelf_aging_screen.dart';
part 'stock_movement_screen.dart';
part 'quantity_review_screen.dart';
part 'expiry_products_screen.dart';
part 'user_billing_screen.dart';
part 'payment_method_screen.dart';
part 'sales_report_screen.dart';
part 'invoice_screen.dart';
part 'user_profile_screen.dart';

Widget buildUserScreen(UserState state) => switch (state.page) {
  UserPage.login => StaffLoginScreen(state),
  UserPage.verification => UserVerificationScreen(state),
  UserPage.dashboard => UserDashboardScreen(state),
  UserPage.inventory => InventoryCategoriesScreen(state),
  UserPage.addProduct => UserAddProductScreen(state),
  UserPage.currentStock => CurrentStockScreen(state),
  UserPage.shelfAging => ShelfAgingScreen(state),
  UserPage.stockMovement => StockMovementScreen(state),
  UserPage.quantityReview => QuantityReviewScreen(state),
  UserPage.expiry => ExpiryProductsScreen(state),
  UserPage.billing => UserBillingScreen(state),
  UserPage.payment => PaymentMethodScreen(state),
  UserPage.reports => SalesReportScreen(state),
  UserPage.invoice => InvoiceScreen(state),
  UserPage.profile => UserProfileScreen(state),
};

// Shared feedback helper used by the user-module screens.
void _notice(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
