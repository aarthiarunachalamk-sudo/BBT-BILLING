import 'package:flutter/material.dart';

import 'admin_screens.dart';
import 'admin_state.dart';
import 'admin_widgets.dart';
import 'video_splash_screen.dart';

class SupermarketAdminApp extends StatefulWidget {
  const SupermarketAdminApp({super.key});

  @override
  State<SupermarketAdminApp> createState() => _SupermarketAdminAppState();
}

class _SupermarketAdminAppState extends State<SupermarketAdminApp> {
  final state = AdminState();

  @override
  void initState() {
    super.initState();
    state.addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    state.removeListener(_refresh);
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Supermarket Billing Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: page,
      visualDensity: VisualDensity.standard,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        primary: blue,
        surface: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 12, color: ink),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(size: 20)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    home: VideoSplashScreen(destination: AdminViewport(state: state)),
  );
}

class AdminViewport extends StatelessWidget {
  const AdminViewport({super.key, required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final screen = buildAdminScreen(state);
    final canExitApp = state.screen == 0 || state.screen == 1;
    return PopScope(
      canPop: canExitApp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (state.loggedIn) {
          state.setNav(0);
        } else {
          state.go(0);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1000) return screen;
          if (state.loggedIn) {
            return Material(
              color: page,
              child: Row(
                children: [
                  SizedBox(
                    width: 270,
                    child: AdminNavigationPanel(state: state),
                  ),
                  Expanded(child: screen),
                ],
              ),
            );
          }
          return _AdminAuthWorkspace(screen: screen);
        },
      ),
    );
  }
}

class _AdminAuthWorkspace extends StatelessWidget {
  const _AdminAuthWorkspace({required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEAF0F8),
    child: Row(
      children: [
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_rounded, color: navy, size: 52),
                SizedBox(height: 20),
                Text(
                  'RUN YOUR STORE\nFROM ONE PLACE',
                  style: TextStyle(
                    fontSize: 40,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: 480,
                  child: Text(
                    'Manage products, people, purchasing, stock, sales, approvals and reporting in one secure admin workspace.',
                    style: TextStyle(fontSize: 16, height: 1.5, color: muted),
                  ),
                ),
                SizedBox(height: 28),
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  children: [
                    _AuthFeature(Icons.verified_user_outlined, 'Secure access'),
                    _AuthFeature(Icons.analytics_outlined, 'Live insights'),
                    _AuthFeature(Icons.inventory_2_outlined, 'Stock control'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 480,
          margin: const EdgeInsets.all(32),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x2203183B),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: screen,
        ),
      ],
    ),
  );
}

class _AuthFeature extends StatelessWidget {
  const _AuthFeature(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 19, color: blue),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
    ],
  );
}
