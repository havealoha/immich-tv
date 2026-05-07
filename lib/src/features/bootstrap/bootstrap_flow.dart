import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BootstrapFlow extends StatelessWidget {
  const BootstrapFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final fontSize = (viewport.width * 0.052).clamp(34.0, 82.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1B4A5A), Color(0xFF10232E), Color(0xFF08131A)],
            center: Alignment(-0.25, -0.8),
            radius: 1.3,
          ),
        ),
        child: Center(
          child: Text(
            'Immich TV',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              height: 0.95,
            ),
          ),
        ),
      ),
    );
  }
}
