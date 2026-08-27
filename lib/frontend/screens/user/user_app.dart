import 'package:flutter/material.dart';

import 'user_models.dart';
import 'user_screens.dart';
import 'user_state.dart';
import 'user_widgets.dart';

class SupermarketUserApp extends StatefulWidget {
  const SupermarketUserApp({super.key});
  @override
  State<SupermarketUserApp> createState() => _SupermarketUserAppState();
}

class _SupermarketUserAppState extends State<SupermarketUserApp> {
  final state = UserState();
  @override
  void initState() {
    super.initState();
    state.initialize();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: userBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: userBlue,
        primary: userBlue,
        surface: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF182B49),
        displayColor: const Color(0xFF182B49),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E2EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: userBlue, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: userBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: userBlue,
          minimumSize: const Size.fromHeight(46),
          side: const BorderSide(color: Color(0xFFB8CAE4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: userNavy,
        indicatorColor: const Color(0xFF1D4F91),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFFB9CBE3),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xFFB9CBE3),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E8F2)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: userNavy,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    child: ListenableBuilder(
      listenable: state,
      builder: (context, child) => PopScope(
        canPop:
            state.page == UserPage.login || state.page == UserPage.dashboard,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) state.go(UserPage.dashboard);
        },
        child: buildUserScreen(state),
      ),
    ),
  );
}
