import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/presentation/app_scale.dart';

class BootstrapFlow extends StatelessWidget {
  const BootstrapFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    final fontSize = scale.text(56, min: 34, max: 64);

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
