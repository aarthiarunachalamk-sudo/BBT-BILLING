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
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) return screen;
        return Material(
          color: const Color(0xFFEAF0F8),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: navy,
                        size: 52,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'SUPERMARKET\nBILLING ADMIN',
                        style: TextStyle(
                          fontSize: 38,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Products, people, purchasing and reporting — managed in one place.',
                        style: TextStyle(fontSize: 16, color: muted),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          adminScreenNames.length,
                          (i) => ActionChip(
                            label: Text(
                              '${i + 1}. ${adminScreenNames[i]}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: state.screen == i
                                ? const Color(0xFFDCEAFF)
                                : Colors.white,
                            side: BorderSide(
                              color: state.screen == i ? blue : line,
                            ),
                            onPressed: () => state.go(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 430,
                margin: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 34,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2603183B),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: screen,
              ),
            ],
          ),
        );
      },
    );
  }
}
