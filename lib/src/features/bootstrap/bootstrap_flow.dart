import 'package:flutter/material.dart';

import '../../shared/presentation/app_scale.dart';

class BootstrapFlow extends StatelessWidget {
  const BootstrapFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: ColoredBox(
        color: Colors.black,
        child: Center(
          child: Image.asset(
            'assets/png/tv-banner-icon.png',
            width: scale.sizeOf(520, min: 280, max: 560),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
