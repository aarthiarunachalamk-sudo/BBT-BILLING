import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bbt_billing/main.dart' as app;
import 'package:bbt_billing/frontend/screens/admin/admin_api.dart';
import 'package:bbt_billing/frontend/screens/admin/admin_app.dart';
import 'package:bbt_billing/frontend/screens/admin/admin_state.dart';
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

    expect(find.text('Choose your workspace'), findsOneWidget);
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(find.text('BBT Billing'), findsOneWidget);
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

  testWidgets('admin workspace can be removed without inherited dependents', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Username or Email'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Choose your workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('23'), findsWidgets);
    expect(find.text("Today's Payments"), findsOneWidget);
    expect(find.text('Total Collection'), findsOneWidget);
    expect(find.text('8.5% vs yesterday'), findsOneWidget);
  });

  test('login opens dashboard before workspace hydration completes', () async {
    final hydrationGate = Completer<void>();
    var hydrationRequests = 0;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/health/')) {
          return http.Response('{}', 200);
        }
        if (request.url.path.endsWith('/auth/login/')) {
          return http.Response(
            jsonEncode({
              'access': 'token',
              'user': {'role': 'admin'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        hydrationRequests += 1;
        await hydrationGate.future;
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final state = AdminState(api: api);
    addTearDown(state.dispose);

    final success = await state
        .login('admin', 'password')
        .timeout(const Duration(seconds: 1));

    expect(success, isTrue);
    expect(state.loggedIn, isTrue);
    expect(state.screen, 1);
    expect(state.refreshing, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // Hydration is sequential so a free-tier server is not flooded with
    // simultaneous requests. Login itself does not wait for this work.
    expect(hydrationRequests, 1);

    hydrationGate.complete();
    while (state.refreshing) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(hydrationRequests, 18);
    expect(state.refreshing, isFalse);
  });

  test(
    'GET retries transient 5xx responses before decoding the list',
    () async {
      var requests = 0;
      final api = AdminApi(
        baseUrl: 'https://example.com/api',
        readRetryBaseDelay: Duration.zero,
        client: MockClient((request) async {
          requests += 1;
          if (requests < 3) {
            return http.Response('{"detail":"starting"}', 503);
          }
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 1, 'name': 'Existing product'},
              ],
              'next': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(api.dispose);

      final products = await api.getList('items');

      expect(requests, 3);
      expect(products.single['name'], 'Existing product');
    },
  );

  test('writes are not retried after a 503 response', () async {
    var requests = 0;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      readRetryBaseDelay: Duration.zero,
      client: MockClient((request) async {
        requests += 1;
        return http.Response('{"detail":"starting"}', 503);
      }),
    );
    addTearDown(api.dispose);

    await expectLater(
      api.create('items', {'name': 'Do not duplicate'}),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 503)),
    );
    expect(requests, 1);
  });

  test('wake-up accepts a structured Django health 503 immediately', () async {
    var requests = 0;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        requests += 1;
        return http.Response(
          jsonEncode({
            'status': 'error',
            'service': 'bbt-billing-api',
            'database': 'migration_required',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(api.dispose);

    final awake = await api.waitForServer(
      maxAttempts: 8,
      initialDelay: Duration.zero,
    );

    expect(awake, isTrue);
    expect(requests, 1);
  });

  test('wake-up retries a generic Render gateway 503', () async {
    var requests = 0;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        requests += 1;
        if (requests == 1) return http.Response('Service Unavailable', 503);
        return http.Response('{}', 200);
      }),
    );
    addTearDown(api.dispose);

    final awake = await api.waitForServer(
      maxAttempts: 2,
      initialDelay: Duration.zero,
    );

    expect(awake, isTrue);
    expect(requests, 2);
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

  test('logged-out users cannot open protected admin screens', () {
    final state = AdminState();
    addTearDown(state.dispose);

    state.go(4);

    expect(state.screen, 0);
    expect(state.loggedIn, isFalse);
  });

  testWidgets('desktop navigation opens the complete admin flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 1;
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, child) => AdminViewport(state: state),
        ),
      ),
    );

    expect(find.text('BBT BILLING'), findsOneWidget);
    expect(find.byTooltip('Open navigation'), findsNothing);
    expect(find.text('Staff Management'), findsOneWidget);
    expect(find.text('Discount Approvals'), findsOneWidget);

    await tester.tap(find.text('Staff Management'));
    await tester.pumpAndSettle();

    expect(state.screen, 2);
    expect(state.navIndex, 1);
    expect(find.text('Staff Management'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('admin-navigation-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Audit Log & Logout'), findsOneWidget);
  });

  testWidgets('account actions and persistent error feedback are reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 4
      ..passwordChangeIdentifier = 'admin'
      ..error = 'Unable to update the product';
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, child) => AdminViewport(state: state),
        ),
      ),
    );

    expect(find.text('Unable to update the product'), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    expect(state.error, isNull);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    expect(state.screen, 16);
    expect(find.text('Change your password'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'admin',
    );
  });

  testWidgets('category search and product filter buttons update results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 6
      ..categories = [
        {'id': 1, 'name': 'Spices', 'is_active': true},
        {'id': 2, 'name': 'Fruit', 'is_active': true},
      ]
      ..products = [
        {'id': 1, 'name': 'Rice', 'stock_status': 'in_stock'},
        {'id': 2, 'name': 'Salt', 'stock_status': 'out_of_stock'},
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, child) => AdminViewport(state: state),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'fruit');
    await tester.pump();
    expect(find.text('Fruit'), findsOneWidget);
    expect(find.text('Spices'), findsNothing);

    state.go(4);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Out of Stock'));
    await tester.pumpAndSettle();

    expect(find.text('Salt'), findsOneWidget);
    expect(find.text('Rice'), findsNothing);
  });

  testWidgets('product catalog presents pricing and stock hierarchy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 4
      ..products = [
        {
          'id': 1,
          'name': 'Fortune Sunlite Refined Sunflower Oil 840 g',
          'sku': 'FORTUNE-SUNLITE-840G',
          'category_name': 'Edible Oils',
          'purchase_price': '145.50',
          'selling_price': '145.50',
          'mrp': '190.00',
          'tax_percent': '5.00',
          'stock_quantity': 24,
          'stock_status': 'in_stock',
          'price_verified_at': '2026-08-19',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));

    expect(find.text('Product Management'), findsOneWidget);
    expect(
      find.text('Fortune Sunlite Refined Sunflower Oil 840 g'),
      findsOneWidget,
    );
    expect(find.textContaining('SKU: FORTUNE-SUNLITE-840G'), findsOneWidget);
    expect(find.textContaining('Total: 24'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/location_icons/general.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/category_icons/grocery.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('GST report button opens a calculated report', (tester) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 14
      ..invoices = [
        {
          'id': 1,
          'number': 'INV-001',
          'taxable_amount': '100.00',
          'cgst_amount': '9.00',
          'sgst_amount': '9.00',
          'total': '118.00',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('GST\nReport'));
    await tester.pumpAndSettle();

    expect(find.text('Taxable Amount'), findsOneWidget);
    expect(find.text('CGST Collected'), findsOneWidget);
    expect(find.byTooltip('Copy as CSV'), findsOneWidget);
  });

  test('staff toggle immediately updates the rendered user data', () async {
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient(
        (_) async => http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final state = AdminState(api: api)
      ..users = [
        {'id': 1, 'first_name': 'Asha', 'last_name': 'Rao', 'is_active': true},
      ];
    addTearDown(state.dispose);

    state.toggleStaff('Asha Rao', false);

    expect(state.users.first['is_active'], isFalse);
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
    'product image is sent with catalog pricing as multipart data',
    () async {
      late http.Request captured;
      final api = AdminApi(
        baseUrl: 'https://example.com/api',
        client: MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path.endsWith('/items/')) {
            captured = request;
            return http.Response(
              jsonEncode({
                'id': 20,
                'name': 'Fortune Sunlite Refined Sunflower Oil 840 g',
                'sku': 'FORTUNE-SUNLITE-840G',
                'selling_price': '145.50',
                'mrp': '190.00',
                'image': '/media/products/sunflower-oil.jpg',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final state = AdminState(api: api);
      addTearDown(state.dispose);

      final product = await state.createProduct(
        {
          'name': 'Fortune Sunlite Refined Sunflower Oil 840 g',
          'sku': 'FORTUNE-SUNLITE-840G',
          'selling_price': '145.50',
          'mrp': '190.00',
        },
        imageBytes: Uint8List.fromList([1, 2, 3]),
        imageName: 'sunflower-oil.jpg',
      );

      expect(captured.method, 'POST');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      final multipartBody = latin1.decode(captured.bodyBytes);
      expect(multipartBody, contains('name="selling_price"'));
      expect(multipartBody, contains('145.50'));
      expect(multipartBody, contains('name="mrp"'));
      expect(multipartBody, contains('190.00'));
      expect(multipartBody, contains('name="image"'));
      expect(multipartBody, contains('filename="sunflower-oil.jpg"'));
      expect(product['image'], contains('sunflower-oil.jpg'));
    },
  );

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
