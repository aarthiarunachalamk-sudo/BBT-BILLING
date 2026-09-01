import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bbt_billing/main.dart' as app;
import 'package:bbt_billing/frontend/screens/admin/admin_api.dart';
import 'package:bbt_billing/frontend/screens/admin/admin_app.dart';
import 'package:bbt_billing/frontend/screens/admin/admin_screens.dart';
import 'package:bbt_billing/frontend/screens/admin/admin_state.dart';
import 'package:bbt_billing/services/barcode_label_service.dart';
import 'package:bbt_billing/frontend/screens/user/user_models.dart';
import 'package:bbt_billing/frontend/screens/user/user_api.dart';
import 'package:bbt_billing/frontend/screens/user/user_screens.dart';
import 'package:bbt_billing/frontend/screens/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
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

  testWidgets('login hides server wake-up attempt copy', (tester) async {
    final state = AdminState()
      ..loading = true
      ..wakingServer = true
      ..wakeAttempt = 2
      ..wakeMaxAttempts = 4;
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Waking up server'), findsNothing);
    expect(find.textContaining('Attempt'), findsNothing);
    expect(find.textContaining('First connection can take'), findsNothing);
  });

  testWidgets('admin workspace can be removed without inherited dependents', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupermarketAdminApp(),
                ),
              ),
              child: const Text('Open admin'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open admin'));
    await tester.pumpAndSettle();
    expect(find.text('Username or Email'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open admin'), findsOneWidget);
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

  test('wake-up uses the lightweight API health endpoint', () async {
    late Uri requestedUri;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response('{"status":"ok"}', 200);
      }),
    );
    addTearDown(api.dispose);

    final awake = await api.waitForServer(
      maxAttempts: 1,
      initialDelay: Duration.zero,
    );

    expect(awake, isTrue);
    expect(requestedUri.path, '/api/health/');
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

  testWidgets('mobile back returns through the actual screen history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 1;
    state.go(4);
    state.go(5);
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    expect(state.screen, 5);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(state.screen, 4);
    expect(find.text('Product Management'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(state.screen, 1);
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation before ending the session', (
    tester,
  ) async {
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
      ..screen = 15;
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Logout?'), findsOneWidget);
    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.loggedIn, isTrue);
    expect(logoutRequests, 0);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(logoutRequests, 1);
    expect(state.loggedIn, isFalse);
    expect(find.text('Admin Login'), findsOneWidget);
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

  testWidgets('updated product price sheet closes without controller errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var scheduleRequests = 0;
    var updateRequests = 0;
    final updatedProduct = <String, dynamic>{
      'id': 1,
      'name': 'Sunflower Oil 1 L',
      'sku': 'OIL-1L',
      'category_name': 'Edible Oils',
      'rack_name': 'General',
      'purchase_price': '110.00',
      'selling_price': '155.00',
      'mrp': '170.00',
      'tax_percent': '5.00',
      'stock_quantity': 12,
      'stock_status': 'in_stock',
      'is_active': true,
    };
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/items/1/price-schedule/')) {
          scheduleRequests += 1;
          return http.Response(
            jsonEncode({'id': 1, 'selling_price': '155.00'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PATCH' &&
            request.url.path.endsWith('/items/1/')) {
          updateRequests += 1;
          return http.Response(
            jsonEncode(updatedProduct),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/items/')) {
          return http.Response(
            jsonEncode([updatedProduct]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/purchase-orders/')) {
          return http.Response(
            '[]',
            200,
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
    final state = AdminState(api: api)
      ..loggedIn = true
      ..screen = 4
      ..products = [
        {...updatedProduct, 'selling_price': '145.00'},
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Sunflower Oil 1 L'));
    await tester.pumpAndSettle();
    expect(find.text('Update Prices'), findsOneWidget);

    final sellingPriceField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Selling Price (₹) *',
    );
    await tester.enterText(sellingPriceField, '155.00');
    await tester.tap(find.text('Update Prices'));
    await tester.pumpAndSettle();

    expect(scheduleRequests, 1);
    expect(updateRequests, 1);
    expect(find.text('Update Prices'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved product opens a product-based sticker flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 4
      ..products = [
        {
          'id': 31,
          'name': 'Premium Tea 250 g',
          'sku': 'TEA-250G',
          'barcode': '2901234567896',
          'manual_details': {
            'sticker_placement': 'custom',
            'sticker_position_x': .35,
            'sticker_position_y': .45,
            'sticker_scale': .9,
            'sticker_rotation_degrees': 90,
            'product_preview_rotation_degrees': 180,
          },
          'category_name': 'Beverages',
          'purchase_price': '110.00',
          'selling_price': '145.00',
          'mrp': '155.00',
          'tax_percent': '5.00',
          'stock_quantity': 18,
          'stock_status': 'in_stock',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    expect(
      find.byKey(const ValueKey('saved-product-sticker-31')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('product-sticker-31')));
    await tester.pumpAndSettle();

    final safePadding = tester.widget<Padding>(
      find.byKey(const Key('product-sticker-sheet-safe-padding')),
    );
    expect(
      safePadding.padding.resolve(TextDirection.ltr).bottom,
      greaterThanOrEqualTo(72),
    );

    expect(find.text('Generate billing sticker'), findsOneWidget);
    expect(find.text('Premium Tea 250 g'), findsWidgets);
    expect(find.text('2901234567896'), findsOneWidget);
    expect(find.text('Beverages'), findsWidgets);
    expect(find.text('MRP · ₹155.00'), findsOneWidget);
    expect(find.text('Open print preview'), findsOneWidget);
  });

  testWidgets('billing product actions update price and delete product', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var patchRequests = 0;
    var deleteRequests = 0;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        if (request.method == 'PATCH' &&
            request.url.path.endsWith('/items/1/')) {
          patchRequests += 1;
          return http.Response(
            jsonEncode({
              'id': 1,
              'name': 'Basmati Rice 5 kg',
              'sku': 'RICE-5KG',
              'selling_price': '725.50',
              'tax_percent': '5.00',
              'stock_quantity': 18,
              'is_active': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE' &&
            request.url.path.endsWith('/items/1/')) {
          deleteRequests += 1;
          return http.Response('', 204);
        }
        if (request.url.path.endsWith('/purchase-orders/')) {
          return http.Response(
            '[]',
            200,
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
    final state = AdminState(api: api)
      ..loggedIn = true
      ..screen = 10
      ..products = [
        {
          'id': 1,
          'name': 'Basmati Rice 5 kg',
          'sku': 'RICE-5KG',
          'selling_price': '760.00',
          'tax_percent': '5.00',
          'stock_quantity': 18,
          'is_active': true,
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    expect(find.text('1 products available'), findsOneWidget);
    expect(find.byTooltip('Scan barcode'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('billing-sticker-product-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('billing-edit-product-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('billing-price-field')),
      '725.50',
    );
    await tester.tap(find.text('Save price'));
    await tester.pumpAndSettle();

    expect(patchRequests, 1);
    expect(state.products.single['selling_price'], '725.50');

    await tester.tap(find.byKey(const ValueKey('billing-delete-product-1')));
    await tester.pumpAndSettle();
    expect(find.text('Delete product?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleteRequests, 1);
    expect(state.products, isEmpty);
    expect(find.text('No products found.'), findsOneWidget);
  });

  test('navigation clears stale page errors', () {
    final state = AdminState()
      ..loggedIn = true
      ..error = 'Cannot reach backend';
    addTearDown(state.dispose);

    state.setNav(2);

    expect(state.screen, 10);
    expect(state.error, isNull);
  });

  testWidgets('GST report button opens a calculated report', (tester) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 14
      ..invoices = [
        {
          'id': 1,
          'number': 'INV-001',
          'invoice_date': DateTime.now().toIso8601String(),
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
    expect(find.byTooltip('Download report'), findsOneWidget);
    expect(find.byKey(const Key('report-calendar-button')), findsOneWidget);
    expect(find.byKey(const Key('report-history-button')), findsOneWidget);
    expect(find.text('GST Collected by Effective Rate'), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-download-button')));
    await tester.pumpAndSettle();
    expect(find.text('Download GST Report'), findsOneWidget);
    expect(find.text('PDF document'), findsOneWidget);
    expect(find.text('CSV spreadsheet'), findsOneWidget);
    expect(find.text('Save report image to Gallery'), findsOneWidget);
  });

  testWidgets('Sales report clearly shows date and download controls', (
    tester,
  ) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 14
      ..invoices = [
        {
          'id': 1,
          'number': 'INV-SALES-001',
          'invoice_date': DateTime.now().toIso8601String(),
          'client_name': 'Walk-in Customer',
          'status': 'paid',
          'taxable_amount': '100.00',
          'cgst_amount': '9.00',
          'sgst_amount': '9.00',
          'discount_amount': '0.00',
          'total': '118.00',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Sales\nReport'));
    await tester.pumpAndSettle();

    expect(find.text('Sales Report'), findsWidgets);
    expect(
      find.text('Invoice totals, tax, discounts and payment status'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-calendar-button')), findsOneWidget);
    expect(find.byKey(const Key('report-download-button')), findsOneWidget);
    expect(find.text('INV-SALES-001'), findsOneWidget);
  });

  testWidgets('Inventory report has as-of date, downloads and history', (
    tester,
  ) async {
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient(
        (_) async => http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final state = AdminState(api: api)
      ..loggedIn = true
      ..screen = 14
      ..products = [
        {
          'id': 1,
          'name': 'Basmati Rice',
          'sku': 'RICE-1',
          'category_name': 'Groceries',
          'purchase_price': '100.00',
          'stock_quantity': 18,
          'reorder_level': 5,
          'stock_status': 'in_stock',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Inventory\nReport'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory Report'), findsWidgets);
    expect(
      find.text('Stock availability, reorder status and cost value'),
      findsOneWidget,
    );
    expect(find.text('Stock as of date'), findsOneWidget);
    expect(find.byKey(const Key('report-download-button')), findsOneWidget);
    expect(find.byKey(const Key('report-history-button')), findsOneWidget);
    expect(find.text('Basmati Rice'), findsOneWidget);
  });

  testWidgets('Purchase report filters and exposes export formats', (
    tester,
  ) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 14
      ..purchaseOrders = [
        {
          'id': 1,
          'number': 'PO-001',
          'order_date': DateTime.now().toIso8601String(),
          'supplier_name': 'BBT Supplier',
          'status': 'received',
          'subtotal': '100.00',
          'tax_amount': '18.00',
          'total': '118.00',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Purchase\nReport'));
    await tester.pumpAndSettle();

    expect(find.text('Purchase Report'), findsWidgets);
    expect(
      find.text('Supplier orders, status and purchase value'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-calendar-button')), findsOneWidget);
    expect(find.text('PO-001'), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-download-button')));
    await tester.pumpAndSettle();
    expect(find.text('Download Purchase Report'), findsOneWidget);
    expect(find.text('PDF document'), findsOneWidget);
    expect(find.text('Save report image to Gallery'), findsOneWidget);
  });

  testWidgets('Profit and loss report uses period sales and sold item cost', (
    tester,
  ) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 14
      ..products = [
        {
          'id': 1,
          'name': 'Basmati Rice',
          'sku': 'RICE-1',
          'purchase_price': '60.00',
          'selling_price': '100.00',
          'stock_quantity': 10,
        },
      ]
      ..invoices = [
        {
          'id': 1,
          'number': 'INV-PL-001',
          'invoice_date': DateTime.now().toIso8601String(),
          'status': 'paid',
          'taxable_amount': '200.00',
          'cgst_amount': '18.00',
          'sgst_amount': '18.00',
          'discount_amount': '5.00',
          'total': '236.00',
          'items': [
            {'item': 1, 'quantity': 2},
          ],
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Profit\n& Loss'));
    await tester.pumpAndSettle();

    expect(find.text('Profit & Loss'), findsWidgets);
    expect(find.text('Net Sales'), findsOneWidget);
    expect(find.text('Estimated COGS'), findsOneWidget);
    expect(find.text('Gross Margin'), findsOneWidget);
    expect(
      find.text('Current Catalog Product Margins (Top 20)'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-calendar-button')), findsOneWidget);
    expect(find.byKey(const Key('report-download-button')), findsOneWidget);
  });

  testWidgets('Stock valuation report supports as-of date and downloads', (
    tester,
  ) async {
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient(
        (_) async => http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final state = AdminState(api: api)
      ..loggedIn = true
      ..screen = 14
      ..products = [
        {
          'id': 1,
          'name': 'Premium Tea',
          'sku': 'TEA-1',
          'category_name': 'Beverages',
          'purchase_price': '60.00',
          'selling_price': '100.00',
          'stock_quantity': 10,
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.tap(find.text('Stock\nValuation'));
    await tester.pumpAndSettle();

    expect(find.text('Stock Valuation'), findsWidgets);
    expect(
      find.text('Cost, retail value and potential stock profit'),
      findsOneWidget,
    );
    expect(find.text('Valuation as of date'), findsOneWidget);
    expect(find.text('Premium Tea'), findsOneWidget);
    expect(find.byKey(const Key('report-history-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('report-download-button')));
    await tester.pumpAndSettle();
    expect(find.text('Download Stock Valuation'), findsOneWidget);
    expect(find.text('PDF document'), findsOneWidget);
    expect(find.text('Save report image to Gallery'), findsOneWidget);
  });

  testWidgets('Admin summary exposes decisions, exports and workflow actions', (
    tester,
  ) async {
    final state = AdminState()
      ..loggedIn = true
      ..screen = 14
      ..dashboard = {
        'outstanding_total': '250.00',
        'overdue_invoice_count': 1,
        'returns_total': '0.00',
      }
      ..products = [
        {
          'id': 1,
          'name': 'Low Stock Product',
          'stock_status': 'low_stock',
          'stock_quantity': 2,
        },
      ]
      ..invoices = [
        {
          'id': 1,
          'number': 'INV-SUM-001',
          'invoice_date': DateTime.now().toIso8601String(),
          'status': 'paid',
          'taxable_amount': '100.00',
          'cgst_amount': '9.00',
          'sgst_amount': '9.00',
          'discount_amount': '0.00',
          'total': '118.00',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    await tester.scrollUntilVisible(
      find.text('Full Summary'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Full Summary'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Summary'), findsWidgets);
    expect(find.text('Business Health'), findsOneWidget);
    expect(find.text('Period Performance'), findsOneWidget);
    expect(find.byKey(const Key('report-calendar-button')), findsOneWidget);
    expect(find.byKey(const Key('report-download-button')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Stock attention'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Stock attention'));
    await tester.pumpAndSettle();

    expect(state.screen, 9);
    expect(find.text('Inventory Alerts'), findsWidgets);
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

  testWidgets('add product can generate a valid printable EAN-13 barcode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AdminState()
      ..loggedIn = true
      ..screen = 5
      ..categories = [
        {'id': 1, 'name': 'Beverages', 'is_active': true},
      ]
      ..racks = [
        {'id': 1, 'name': 'Rack 1', 'is_active': true},
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    expect(find.text('Barcode setup'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Generate new'), findsOneWidget);

    await tester.tap(find.text('Generate new'));
    await tester.pump();

    final barcodeField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Barcode Number / SKU *'),
    );
    final barcode = barcodeField.controller!.text;
    expect(barcode, matches(RegExp(r'^29\d{11}$')));
    final body = barcode.substring(0, 12);
    var sum = 0;
    for (var index = 0; index < body.length; index++) {
      final digit = int.parse(body[index]);
      sum += index.isEven ? digit : digit * 3;
    }
    expect(int.parse(barcode[12]), (10 - (sum % 10)) % 10);
    expect(find.textContaining('Valid EAN-13'), findsOneWidget);
    expect(find.text('50 × 25 mm label'), findsOneWidget);
    expect(find.text('Print after save'), findsOneWidget);
    expect(find.text('Department Name *'), findsOneWidget);
  });

  testWidgets('final add product step previews sticker placement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? createBody;
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/items/')) {
          createBody = (jsonDecode(request.body) as Map)
              .cast<String, dynamic>();
          return http.Response(
            jsonEncode({...createBody!, 'id': 51}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/dashboard/')) {
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final state = AdminState(api: api)
      ..loggedIn = true
      ..screen = 5
      ..categories = [
        {'id': 1, 'name': 'Beverages', 'is_active': true},
      ]
      ..racks = [
        {'id': 1, 'name': 'Rack 1', 'is_active': true},
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(home: AdminViewport(state: state)));
    final dynamic formState = tester.state(find.byType(AddProductScreen));
    formState.name.text = 'Premium Tea 250 g';
    formState.sku.text = '2901234567896';
    formState.purchasePrice.text = '110.00';
    formState.sellingPrice.text = '145.00';
    formState.mrp.text = '155.00';
    formState.openingStock.text = '10';
    formState.setState(() {
      formState.categoryId = 1;
      formState.gst = 5;
      formState.rackLocation = 'Rack 1';
      formState.productImageBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      formState.printAfterSave = false;
      formState.currentStep = 3;
    });
    await tester.pumpAndSettle();

    expect(find.text('Product & sticker preview'), findsOneWidget);
    expect(find.text('Step 4 of 4  •  Review before saving'), findsOneWidget);
    expect(find.byKey(const Key('product-sticker-preview')), findsOneWidget);
    expect(find.text('Premium Tea 250 g'), findsWidgets);
    expect(find.text('MRP ₹155.00'), findsOneWidget);
    expect(find.text('6% OFF'), findsWidgets);
    expect(find.text('Add Product'), findsNWidgets(2));

    await tester.drag(
      find.byKey(const Key('draggable-product-sticker')),
      const Offset(-45, -25),
    );
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const ValueKey('product-rotation-360')),
    );
    await tester.tap(find.byKey(const ValueKey('product-rotation-360')));
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('sticker-size-decrease')));
    await tester.tap(find.byKey(const Key('sticker-size-decrease')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('sticker-rotation-90')),
    );
    await tester.tap(find.byKey(const ValueKey('sticker-rotation-90')));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('add-product-primary-action')),
    );
    await tester.tap(find.byKey(const Key('add-product-primary-action')));
    await tester.pumpAndSettle();

    final manualDetails = (createBody?['manual_details'] as Map)
        .cast<String, dynamic>();
    expect(manualDetails['sticker_placement'], 'custom');
    expect(manualDetails['sticker_position_x'], greaterThan(0));
    expect(manualDetails['sticker_position_y'], greaterThan(0));
    expect(manualDetails['sticker_scale'], .9);
    expect(manualDetails['sticker_rotation_degrees'], 90);
    expect(manualDetails['product_preview_rotation_degrees'], 360);
    expect(manualDetails['sticker_format'], 'compact50x25');
    expect(manualDetails['sticker_discount_percent'], 6);
    expect(state.screen, 4);
  });

  test('barcode label PDF is generated for label and A4 formats', () async {
    for (final format in [
      BarcodeLabelFormat.compact50x25,
      BarcodeLabelFormat.a4Sheet,
    ]) {
      final bytes = await buildBarcodeLabelPdf(
        productName: 'Premium Tea 250 g',
        barcode: '2901234567896',
        price: '125.00',
        department: 'Beverages',
        sellingPrice: '110.00',
        discountPercent: 12,
        format: format,
        copies: format == BarcodeLabelFormat.a4Sheet ? 24 : 2,
      );
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });

  testWidgets('user Add Product has the admin barcode and print workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = UserState()
      ..loading = false
      ..page = UserPage.addProduct
      ..categories = [
        {'id': 1, 'name': 'Beverages', 'is_active': true},
      ]
      ..racks = [
        {'id': 1, 'name': 'Fridge', 'is_active': true},
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (_, _) => buildUserScreen(state),
        ),
      ),
    );

    expect(find.text('Barcode setup'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Generate new'), findsOneWidget);
    expect(find.text('50 × 25 mm label'), findsOneWidget);
    expect(find.text('Print after save'), findsOneWidget);

    await tester.tap(find.text('Generate new'));
    await tester.pump();
    final barcodeField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Barcode Number / SKU *'),
    );
    expect(barcodeField.controller!.text, matches(RegExp(r'^29\d{11}$')));
    expect(find.textContaining('Valid EAN-13'), findsOneWidget);
  });

  testWidgets('user final product step matches the admin sticker editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, dynamic>? createBody;
    final api = UserApi(
      client: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/products/')) {
          createBody = (jsonDecode(request.body) as Map)
              .cast<String, dynamic>();
          return http.Response(
            jsonEncode({...createBody!, 'id': 61}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/categories/')) {
          return http.Response(
            jsonEncode([
              {'id': 1, 'name': 'Beverages', 'is_active': true},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final state = UserState(api: api)
      ..loading = false
      ..page = UserPage.addProduct
      ..categories = [
        {'id': 1, 'name': 'Beverages', 'is_active': true},
      ]
      ..racks = [
        {'id': 1, 'name': 'Fridge', 'is_active': true},
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (_, _) => buildUserScreen(state),
        ),
      ),
    );
    final dynamic formState = tester.state(find.byType(UserAddProductScreen));
    formState.name.text = 'Premium Milk 1 L';
    formState.sku.text = '2901234567896';
    formState.purchasePrice.text = '50.00';
    formState.sellingPrice.text = '60.00';
    formState.mrp.text = '75.00';
    formState.openingStock.text = '10';
    formState.setState(() {
      formState.categoryId = 1;
      formState.gst = 5;
      formState.rackLocation = 'Fridge';
      formState.productImageBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      formState.printAfterSave = false;
      formState.currentStep = 3;
    });
    await tester.pumpAndSettle();

    expect(find.text('Product & sticker preview'), findsOneWidget);
    expect(find.text('Step 4 of 4  •  Review before saving'), findsOneWidget);
    expect(find.text('20% OFF'), findsWidgets);
    final dragTarget = tester.widget<GestureDetector>(
      find.byKey(const Key('user-draggable-product-sticker')),
    );
    dragTarget.onPanUpdate!(
      DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(-80, 0),
      ),
    );
    await tester.pump();
    expect(formState.customStickerPosition, isTrue);
    await tester.ensureVisible(
      find.byKey(const ValueKey('user-product-rotation-360')),
    );
    await tester.tap(find.byKey(const ValueKey('user-product-rotation-360')));
    await tester.ensureVisible(
      find.byKey(const Key('user-sticker-size-decrease')),
    );
    await tester.tap(find.byKey(const Key('user-sticker-size-decrease')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('user-sticker-rotation-90')),
    );
    await tester.tap(find.byKey(const ValueKey('user-sticker-rotation-90')));
    await tester.ensureVisible(
      find.byKey(const Key('user-add-product-primary-action')),
    );
    await tester.tap(find.byKey(const Key('user-add-product-primary-action')));
    await tester.pumpAndSettle();

    final manualDetails = (createBody?['manual_details'] as Map)
        .cast<String, dynamic>();
    expect(manualDetails['sticker_placement'], 'custom');
    expect(manualDetails['sticker_scale'], .9);
    expect(manualDetails['sticker_rotation_degrees'], 90);
    expect(manualDetails['product_preview_rotation_degrees'], 360);
    expect(manualDetails['sticker_discount_percent'], 20);
    expect(state.page, UserPage.inventory);
  });

  test('user multipart product upload JSON-encodes sticker metadata', () async {
    late http.Request captured;
    final api = UserApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'id': 71}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await api.uploadProduct(
      {
        'name': 'Premium Milk 1 L',
        'manual_details': {
          'sticker_placement': 'custom',
          'sticker_scale': .8,
          'sticker_rotation_degrees': 90,
        },
      },
      image: XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'milk.jpg',
        mimeType: 'image/jpeg',
      ),
    );

    final multipartBody = latin1.decode(captured.bodyBytes);
    expect(multipartBody, contains('name="manual_details"'));
    expect(multipartBody, contains('"sticker_placement":"custom"'));
    expect(multipartBody, contains('"sticker_rotation_degrees":90'));
  });

  testWidgets('user product list displays the saved barcode', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = UserState()
      ..loading = false
      ..page = UserPage.inventory
      ..user = {'role': 'inventory'}
      ..products = [
        {
          'product_id': 81,
          'product_name': 'Premium Milk 1 L',
          'sku': 'MILK-1L',
          'barcode': '2901234567896',
          'manual_details': {
            'sticker_placement': 'custom',
            'sticker_position_x': .2,
            'sticker_position_y': .3,
            'sticker_scale': 1.1,
            'sticker_rotation_degrees': 90,
            'product_preview_rotation_degrees': 270,
          },
          'store_quantity': 10,
          'minimum_quantity': 2,
          'category_name': 'Dairy',
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (_, _) => buildUserScreen(state),
        ),
      ),
    );

    expect(find.text('Premium Milk 1 L'), findsOneWidget);
    expect(find.text('Barcode: 2901234567896'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('saved-product-sticker-81')),
      findsOneWidget,
    );
  });

  testWidgets(
    'user billing shows discount request and pending approval state',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = UserState()
        ..loading = false
        ..page = UserPage.billing;
      state.addProduct({
        'id': 1,
        'name': 'Premium Tea',
        'selling_price': '100.00',
        'tax_percent': '5.00',
        'stock_quantity': 5,
      });
      addTearDown(state.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AnimatedBuilder(
            animation: state,
            builder: (_, _) => buildUserScreen(state),
          ),
        ),
      );
      expect(find.text('Request Discount'), findsOneWidget);

      state.discountApproval = {
        'id': 7,
        'status': 'pending',
        'requested_percent': '20.00',
      };
      state.notify();
      await tester.pump();
      expect(find.text('Waiting for Admin Approval'), findsWidgets);
      expect(find.text('Check Approval'), findsOneWidget);
    },
  );

  testWidgets('user billing matches admin catalogue and cart actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = UserState()
      ..loading = false
      ..page = UserPage.billing
      ..user = {'role': 'cashier'}
      ..products = [
        {
          'id': 21,
          'name': 'Premium Tea 250 g',
          'sku': 'TEA-250',
          'barcode': '2901234567896',
          'selling_price': '125.00',
          'tax_percent': '5.00',
          'stock_quantity': 8,
          'is_active': true,
        },
      ];
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (_, _) => buildUserScreen(state),
        ),
      ),
    );

    expect(find.byTooltip('Scan barcode'), findsOneWidget);
    expect(find.text('1 products available'), findsOneWidget);
    expect(find.text('TEA-250'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-billing-edit-product-21')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('user-billing-delete-product-21')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('user-billing-add-product-21')));
    await tester.pump();
    expect(find.text('Clear (1)'), findsOneWidget);
    expect(find.textContaining('₹125.00 × 1'), findsOneWidget);
    expect(find.text('Proceed to Payment'), findsOneWidget);
  });

  test('user approved discount is included in checkout exactly once', () async {
    Map<String, dynamic>? checkoutBody;
    final api = UserApi(
      client: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/discount-approvals/request-billing/')) {
          return http.Response(
            jsonEncode({
              'id': 7,
              'status': 'pending',
              'requested_percent': '20.00',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/discount-approvals/')) {
          return http.Response(
            jsonEncode([
              {
                'id': 7,
                'status': 'approved',
                'requested_percent': '20.00',
                'review_note': 'Approved',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith('/billing/checkout/')) {
          checkoutBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'id': 99, 'number': 'INV-99'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/invoices/')) {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final state = UserState(api: api)..loading = false;
    addTearDown(state.dispose);
    state.addProduct({
      'id': 1,
      'name': 'Premium Tea',
      'selling_price': '100.00',
      'tax_percent': '5.00',
      'stock_quantity': 5,
    });

    expect(await state.requestDiscount(20, 'Loyal customer'), isTrue);
    expect(state.discountPending, isTrue);
    expect(await state.refreshDiscountApproval(), isTrue);
    expect(state.discountApproved, isTrue);
    expect(state.grandTotal, 84.0);
    expect(
      await state.checkout([
        {'method': 'cash', 'amount': '84.00'},
      ]),
      isTrue,
    );
    expect(checkoutBody?['discount_percent'], '20.00');
    expect(checkoutBody?['discount_approval'], 7);
    expect(state.discountApproval, isEmpty);
    expect(state.discountPercent, 0);
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

  test('product save request times out with a recoverable message', () async {
    final pendingResponse = Completer<http.Response>();
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      writeTimeout: const Duration(milliseconds: 10),
      client: MockClient((_) => pendingResponse.future),
    );
    addTearDown(api.dispose);

    expect(
      () => api.create('items', {'name': 'Slow product'}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });

  test('product creation does not wait for dashboard refresh', () async {
    final dashboardResponse = Completer<http.Response>();
    final api = AdminApi(
      baseUrl: 'https://example.com/api',
      client: MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/items/')) {
          return http.Response(
            jsonEncode({'id': 40, 'name': 'Fast Product', 'sku': 'FAST-40'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/dashboard/')) {
          return dashboardResponse.future;
        }
        return http.Response('{}', 404);
      }),
    );
    final state = AdminState(api: api);
    addTearDown(state.dispose);

    final product = await state.createProduct({'name': 'Fast Product'});

    expect(product['id'], 40);
    expect(state.products.single['name'], 'Fast Product');
    dashboardResponse.complete(
      http.Response(
        jsonEncode({'total_products': 1}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await Future<void>.delayed(Duration.zero);
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
