import 'dart:convert';

import 'package:bbt_billing/main.dart' as app;
import 'package:bbt_billing/frontend/admin/admin_api.dart';
import 'package:bbt_billing/frontend/admin/admin_app.dart';
import 'package:bbt_billing/frontend/admin/admin_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, child) => AdminViewport(state: state),
        ),
      ),
    );

    expect(find.text('₹ 45320.00'), findsOneWidget);
    expect(find.text('256'), findsOneWidget);
    expect(find.text('₹ 12850.00'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('↑ 8.5% vs yesterday'), findsOneWidget);
  });

  testWidgets('Android back returns an admin sub-screen to dashboard', (
    tester,
  ) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 4;
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, child) => AdminViewport(state: state),
        ),
      ),
    );
    expect(find.text('Product Management'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(state.screen, 1);
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('empty add product screen offers category creation', (
    tester,
  ) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 5;
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    expect(
      find.text('Create a category before adding a product.'),
      findsOneWidget,
    );
    expect(find.text('Add Category'), findsOneWidget);

    await tester.tap(find.text('Add Category'));
    await tester.pumpAndSettle();
    expect(find.text('Category name'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  test('existing category is reused without another backend request', () async {
    final state = AdminState()
      ..categories = [
        {'id': 1, 'name': 'Turmeric powder', 'is_active': true},
      ];
    addTearDown(state.dispose);

    await state.createCategory('  TURMERIC POWDER  ');

    expect(state.categories, hasLength(1));
  });

  test('API list errors are displayed without square brackets', () async {
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'name': ['category with this name already exists.'],
          }),
          400,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(api.dispose);

    expect(
      () => api.create('categories', {'name': 'Turmeric powder'}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'category with this name already exists.',
        ),
      ),
    );
  });

  test('saved product is added to the dynamic product list', () async {
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/items/')) {
          return http.Response(
            jsonEncode({
              'id': 10,
              'item_type': 'material',
              'name': 'Turmeric Powder 250g',
              'sku': 'TURMERIC-001',
              'category': 1,
              'category_name': 'Spices',
              'unit': 'Pack',
              'purchase_price': '40.00',
              'selling_price': '55.00',
              'tax_percent': '5.00',
              'stock_quantity': 20,
              'reorder_level': 5,
              'stock_status': 'in_stock',
              'is_active': true,
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/dashboard/')) {
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final state = AdminState(api: api);
    addTearDown(state.dispose);

    final product = await state.createProduct({'name': 'Turmeric Powder 250g'});

    expect(product['sku'], 'TURMERIC-001');
    expect(state.products, hasLength(1));
    expect(state.products.first['category_name'], 'Spices');
  });

  test(
    'logout confirms, calls backend, and clears dynamic session data',
    () async {
      var logoutRequests = 0;
      final api = AdminApi(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/auth/logout/')) {
            logoutRequests += 1;
            return http.Response(
              jsonEncode({'detail': 'Logged out successfully.'}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      final state = AdminState(api: api)
        ..loggedIn = true
        ..screen = 15
        ..dashboard = {'today_sales': '100.00'}
        ..products = [
          {'id': 1, 'name': 'Turmeric Powder'},
        ]
        ..categories = [
          {'id': 1, 'name': 'Spices'},
        ];
      addTearDown(state.dispose);

      state.showLogoutConfirmation();
      expect(state.logoutConfirmationVisible, isTrue);

      await state.logout();

      expect(logoutRequests, 1);
      expect(state.loggedIn, isFalse);
      expect(state.screen, 0);
      expect(state.logoutConfirmationVisible, isFalse);
      expect(state.dashboard, isEmpty);
      expect(state.products, isEmpty);
      expect(state.categories, isEmpty);
    },
  );
}
