import 'package:flutter/material.dart';

import 'src/app_shell.dart';

void runImmichTvApp() {
  runApp(const ImmichTvApp());
}

class ImmichTvApp extends StatelessWidget {
  const ImmichTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E847F),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF08131A),
    );

    return MaterialApp(
      title: 'ImmichTV',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        cardTheme: baseTheme.cardTheme.copyWith(
          color: const Color(0xFF10232D),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF1E3947)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F2029),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2A4656)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2A4656)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF6FE0DB), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFFB6D6D4)),
        ),
      ),
      home: const AppShell(),
    );
  }
}
