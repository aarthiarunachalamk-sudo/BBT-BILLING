import 'package:bbt_billing/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin login renders backend credentials form', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Welcome Admin'), findsOneWidget);
    expect(find.text('Username or Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
