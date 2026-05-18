import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_scale.dart';

class BootstrapFlow extends StatelessWidget {
  const BootstrapFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    final fontSize = scale.text(56, min: 34, max: 64);
    final versionTextStyle = GoogleFonts.inter(
      color: Colors.white.withValues(alpha: 0.62),
      fontSize: scale.text(14, min: 12, max: 16),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      height: 1.2,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Immich TV',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.1,
                  height: 0.96,
                ),
              ),
              SizedBox(height: scale.space(10, min: 8, max: 12)),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final packageInfo = snapshot.data;
                  if (packageInfo == null) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    'v${packageInfo.version} (${packageInfo.buildNumber})',
                    textAlign: TextAlign.center,
                    style: versionTextStyle,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
