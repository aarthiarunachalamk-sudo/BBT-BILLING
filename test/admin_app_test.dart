import 'package:bbt_billing/main.dart' as app;
import 'package:bbt_billing/frontend/admin/admin_app.dart';
import 'package:bbt_billing/frontend/admin/admin_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login remember me and change password navigation work', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Welcome Admin'), findsOneWidget);
    expect(find.text('Username or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'aarthi');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('admin_remember_me'), isTrue);
    expect(preferences.getString('admin_login_identifier'), 'aarthi');

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Change your password'), findsOneWidget);
    expect(find.text('Current Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
  });

  testWidgets('dashboard renders dynamic API state values', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..screen = 1
      ..dashboard = {
        'today_sales': '45320.00',
        'sales_growth': '8.5',
        'total_bills': 256,
        'bills_growth': '6.3',
        'profit': '12850.00',
        'profit_growth': '7.2',
        'low_stock_count': 23,
        'pending_discount_approvals': 12,
        'pending_purchase_orders': 7,
      };
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));

    expect(find.text('₹ 45320.00'), findsOneWidget);
    expect(find.text('256'), findsOneWidget);
    expect(find.text('₹ 12850.00'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('↑ 8.5% vs yesterday'), findsOneWidget);
  });
}
