import 'package:flutter/material.dart';

import 'user_models.dart';
import 'user_screens.dart';
import 'user_state.dart';
import 'user_widgets.dart';

class SupermarketUserApp extends StatefulWidget {
  const SupermarketUserApp({super.key});
  @override State<SupermarketUserApp> createState() => _SupermarketUserAppState();
}

class _SupermarketUserAppState extends State<SupermarketUserApp> {
  final state = UserState();
  @override void initState() { super.initState(); state.initialize(); }
  @override void dispose() { state.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'BBT Staff Billing',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: userBg, colorScheme: ColorScheme.fromSeed(seedColor: userBlue),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: userBlue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    ),
    home: ListenableBuilder(listenable: state, builder: (_, __) => PopScope(
      canPop: state.page == UserPage.login || state.page == UserPage.dashboard,
      onPopInvokedWithResult: (didPop, result) { if (!didPop) state.go(UserPage.dashboard); }, child: buildUserScreen(state),
    )),
  );
}
