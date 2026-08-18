import 'package:bbt_billing/main.dart' as app;
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
}
