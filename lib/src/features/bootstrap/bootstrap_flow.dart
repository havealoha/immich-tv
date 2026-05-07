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
      backgroundColor: Colors.black,
      body: ColoredBox(
        color: Colors.black,
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
