import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../platform/browser_navigation.dart';
import '../../shared/presentation/app_colors.dart';

const _repoUrl = 'https://github.com/WorkWithAfridi/immich-tv';
const _issuesUrl = 'https://github.com/WorkWithAfridi/immich-tv/issues';
const _releasesUrl = 'https://github.com/WorkWithAfridi/immich-tv/releases';

const _coreFeatures = <_MarketingFeature>[
  _MarketingFeature(
    icon: Icons.tv_rounded,
    title: 'Designed for TV from the start',
    body:
        'Remote navigation, clear focus states, and readable spacing make the app feel native on Android TV and Google TV.',
  ),
  _MarketingFeature(
    icon: Icons.photo_library_outlined,
    title: 'Built around your Immich server',
    body:
        'Sign in with your existing Immich account and browse timeline photos, albums, favorites, videos, and slideshows on the biggest screen in your home.',
  ),
  _MarketingFeature(
    icon: Icons.slideshow_rounded,
    title: 'Calm, read-focused experience',
    body:
        'Immich TV is optimized for viewing and playback, keeping the living-room experience simple, safe, and comfortable.',
  ),
];

const _productDetails = <String>[
  'Timeline browsing grouped by day with fast year jumps',
  'Fullscreen photo and video playback with smooth navigation',
  'Albums, favorites, and slideshow playback in one TV-first flow',
  'Saved local profiles with secure storage for returning sessions',
];

const _faqItems = <_FaqItem>[
  _FaqItem(
    question: 'What is Immich TV?',
    answer:
        'Immich TV is an open source television client for browsing a self-hosted Immich library on Android TV and Google TV.',
  ),
  _FaqItem(
    question: 'Do I need my own Immich server?',
    answer:
        'Yes for normal use. There is also a dedicated demo mode so testers can preview the experience without connecting a real library.',
  ),
  _FaqItem(
    question: 'Can I contribute to the project?',
    answer:
        'Yes. The repository is public on GitHub, so you can open issues, star the project, and contribute improvements.',
  ),
];

class MarketingLandingScreen extends StatefulWidget {
  const MarketingLandingScreen({super.key, required this.onOpenWebApp});

  final VoidCallback onOpenWebApp;

  @override
  State<MarketingLandingScreen> createState() => _MarketingLandingScreenState();
}

class _MarketingLandingScreenState extends State<MarketingLandingScreen> {
  bool _useDarkTheme = true;

  @override
  Widget build(BuildContext context) {
    final palette = _useDarkTheme
        ? const _LandingPalette.dark()
        : const _LandingPalette.light();
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    final headlineStyle = GoogleFonts.instrumentSerif(
      fontSize: isWide ? 72 : 44,
      height: 0.92,
      letterSpacing: -2.4,
      color: palette.text,
    );
    final bodyStyle = GoogleFonts.manrope(
      fontSize: isWide ? 18 : 16,
      fontWeight: FontWeight.w500,
      height: 1.7,
      color: palette.muted,
    );

    return AnimatedTheme(
      duration: const Duration(milliseconds: 220),
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: palette.background,
        textTheme: GoogleFonts.manropeTextTheme().apply(
          bodyColor: palette.text,
          displayColor: palette.text,
        ),
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.backgroundGradient),
          child: Stack(
            children: [
              Positioned(
                left: -120,
                top: 120,
                child: _BlurOrb(color: palette.orbA, size: 320),
              ),
              Positioned(
                right: -80,
                top: 64,
                child: _BlurOrb(color: palette.orbB, size: 280),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GridPainter(color: palette.grid),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(
                            palette: palette,
                            useDarkTheme: _useDarkTheme,
                            onToggleTheme: () {
                              setState(() => _useDarkTheme = !_useDarkTheme);
                            },
                          ),
                          const SizedBox(height: 44),
                          Wrap(
                            spacing: 32,
                            runSpacing: 32,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: isWide ? 520 : double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Eyebrow(
                                      palette: palette,
                                      label:
                                          'Immich for Android TV and Google TV',
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'A minimal, TV-first way to enjoy your self-hosted photo library.',
                                      style: headlineStyle,
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Immich TV brings timeline browsing, albums, favorites, video playback, and slideshows into a clean large-screen interface built for the couch instead of a touch screen.',
                                      style: bodyStyle,
                                    ),
                                    const SizedBox(height: 28),
                                    Wrap(
                                      spacing: 14,
                                      runSpacing: 14,
                                      children: [
                                        _PrimaryButton(
                                          label: 'Open web app preview',
                                          onPressed: widget.onOpenWebApp,
                                        ),
                                        _SecondaryButton(
                                          label: 'Download APK',
                                          palette: palette,
                                          onPressed: () =>
                                              openExternalUrl(_releasesUrl),
                                        ),
                                        _SecondaryButton(
                                          label: 'View on GitHub',
                                          palette: palette,
                                          onPressed: () =>
                                              openExternalUrl(_repoUrl),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: const [
                                        _HighlightChip(
                                          label: 'Remote-first navigation',
                                        ),
                                        _HighlightChip(
                                          label: 'Self-hosted Immich support',
                                        ),
                                        _HighlightChip(
                                          label:
                                              'Fullscreen playback and slideshow',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _HeroFrame(palette: palette),
                            ],
                          ),
                          const SizedBox(height: 72),
                          _SectionHeading(
                            palette: palette,
                            eyebrow: 'Why it feels right on TV',
                            title:
                                'Focused on clarity, playback, and comfortable browsing from a distance.',
                            body:
                                'Most gallery apps arrive on television as stretched touch UIs. Immich TV is different. It is shaped around how people actually browse media in a living room.',
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 18,
                            runSpacing: 18,
                            children: _coreFeatures
                                .map(
                                  (feature) => _FeatureCard(
                                    feature: feature,
                                    palette: palette,
                                    wide: isWide,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 72),
                          _SectionHeading(
                            palette: palette,
                            eyebrow: 'Core experience',
                            title:
                                'Everything you need for relaxed large-screen browsing, without clutter.',
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _productDetails
                                .map(
                                  (detail) => _DetailChip(
                                    detail: detail,
                                    palette: palette,
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 72),
                          Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              _InfoPanel(
                                palette: palette,
                                eyebrow: 'Download APK',
                                title:
                                    'Install the latest signed Android TV build directly from GitHub Releases.',
                                body:
                                    'Each push to the master branch builds a signed release APK and updates the public download asset. Use GitHub Releases for the newest build or to browse specific versions.',
                                primaryActionLabel: 'Open releases',
                                onPrimaryAction: () =>
                                    openExternalUrl(_releasesUrl),
                                secondaryActionLabel: 'Browse releases',
                                onSecondaryAction: () =>
                                    openExternalUrl(_releasesUrl),
                                footerLabel:
                                    'github.com/WorkWithAfridi/immich-tv/releases',
                              ),
                              _InfoPanel(
                                palette: palette,
                                eyebrow: 'Demo access',
                                title:
                                    'Use the exact demo URL to unlock sample media and test the flow.',
                                body:
                                    'Demo mode only appears when the tester enters the exact server URL below, keeping the production sign-in path separate from the sample experience.',
                                content: _DemoCredentials(palette: palette),
                              ),
                            ],
                          ),
                          const SizedBox(height: 72),
                          _InfoPanel(
                            palette: palette,
                            eyebrow: 'Open source',
                            title:
                                'Explore the repository, star the project, or contribute improvements.',
                            body:
                                'The app and the web landing page now live in one Flutter codebase, making it easier to evolve the public site and the browser app together.',
                            primaryActionLabel: 'Open repo',
                            onPrimaryAction: () => openExternalUrl(_repoUrl),
                            secondaryActionLabel: 'Contribute',
                            onSecondaryAction: () =>
                                openExternalUrl(_issuesUrl),
                            footerLabel: 'github.com/WorkWithAfridi/immich-tv',
                          ),
                          const SizedBox(height: 72),
                          _SectionHeading(
                            palette: palette,
                            eyebrow: 'FAQ',
                            title: 'Key questions before installation.',
                          ),
                          const SizedBox(height: 24),
                          ..._faqItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _FaqCard(item: item, palette: palette),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.palette,
    required this.useDarkTheme,
    required this.onToggleTheme,
  });

  final _LandingPalette palette;
  final bool useDarkTheme;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/png/playstore.png',
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open source TV client',
                style: GoogleFonts.manrope(
                  color: palette.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Immich TV',
                style: GoogleFonts.manrope(
                  color: palette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onToggleTheme,
          style: IconButton.styleFrom(
            backgroundColor: palette.surfaceStrong,
            foregroundColor: palette.text,
            side: BorderSide(color: palette.lineStrong),
          ),
          icon: Icon(
            useDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
          tooltip: 'Toggle color theme',
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.palette,
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final _LandingPalette palette;
  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 960;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(palette: palette, label: eyebrow),
        const SizedBox(height: 14),
        Text(
          title,
          style: GoogleFonts.instrumentSerif(
            fontSize: isWide ? 54 : 34,
            height: 0.98,
            letterSpacing: -1.6,
            color: palette.text,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              body!,
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.75,
                color: palette.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.palette, required this.label});

  final _LandingPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.manrope(
        color: palette.accent,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.1,
      ),
    );
  }
}

class _HeroFrame extends StatelessWidget {
  const _HeroFrame({required this.palette});

  final _LandingPalette palette;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width >= 960
        ? 520.0
        : MediaQuery.sizeOf(context).width - 48;
    return Container(
      width: width.clamp(280.0, 520.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: palette.heroFrame,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 44,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/png/banner.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.feature,
    required this.palette,
    required this.wide,
  });

  final _MarketingFeature feature;
  final _LandingPalette palette;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 360 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: palette.iconWell,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(feature.icon, color: palette.text),
          ),
          const SizedBox(height: 18),
          Text(
            feature.title,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            feature.body,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.7,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.detail, required this.palette});

  final String detail;
  final _LandingPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: palette.accent, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              detail,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.palette,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.footerLabel,
    this.content,
  });

  final _LandingPalette palette;
  final String eyebrow;
  final String title;
  final String body;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? footerLabel;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width >= 960 ? 560 : double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(palette: palette, label: eyebrow),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.instrumentSerif(
              fontSize: 36,
              height: 0.98,
              letterSpacing: -1,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.7,
              color: palette.muted,
            ),
          ),
          if (content != null) ...[const SizedBox(height: 24), content!],
          if (primaryActionLabel != null || secondaryActionLabel != null) ...[
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (primaryActionLabel != null)
                  _PrimaryButton(
                    label: primaryActionLabel!,
                    onPressed: onPrimaryAction ?? () {},
                  ),
                if (secondaryActionLabel != null)
                  _SecondaryButton(
                    label: secondaryActionLabel!,
                    palette: palette,
                    onPressed: onSecondaryAction ?? () {},
                  ),
              ],
            ),
          ],
          if (footerLabel != null) ...[
            const SizedBox(height: 20),
            Text(
              footerLabel!,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials({required this.palette});

  final _LandingPalette palette;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: const [
        _CredentialTile(
          label: 'Demo URL',
          value: 'https://demo.immichtv.local',
        ),
        _CredentialTile(label: 'Email', value: 'demo@immich.tv'),
        _CredentialTile(label: 'Password', value: 'demo1234'),
      ].map((tile) => tile.copyWith(palette: palette)).toList(growable: false),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  const _CredentialTile({
    required this.label,
    required this.value,
    this.palette,
  });

  final String label;
  final String value;
  final _LandingPalette? palette;

  _CredentialTile copyWith({_LandingPalette? palette}) {
    return _CredentialTile(label: label, value: value, palette: palette);
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = palette!;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: activePalette.surfaceStrong,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: activePalette.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: activePalette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.item, required this.palette});

  final _FaqItem item;
  final _LandingPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.question,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.answer,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.7,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.immichBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final _LandingPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        side: BorderSide(color: palette.lineStrong),
        backgroundColor: palette.secondaryButton,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).scaffoldBackgroundColor.computeLuminance() < 0.3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0x1A10212D),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFB0C4CC) : const Color(0xFF415966),
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 44.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _MarketingFeature {
  const _MarketingFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _LandingPalette {
  const _LandingPalette({
    required this.background,
    required this.backgroundGradient,
    required this.surface,
    required this.surfaceStrong,
    required this.text,
    required this.muted,
    required this.accent,
    required this.line,
    required this.lineStrong,
    required this.orbA,
    required this.orbB,
    required this.grid,
    required this.shadow,
    required this.heroFrame,
    required this.secondaryButton,
    required this.iconWell,
  });

  const _LandingPalette.dark()
    : background = const Color(0xFF071017),
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFF050C11), Color(0xFF091219), Color(0xFF071017)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      surface = const Color(0xB80D171E),
      surfaceStrong = const Color(0xE60D171E),
      text = const Color(0xFFEFF5F8),
      muted = const Color(0xFF9DB2BC),
      accent = const Color(0xFF91DDC5),
      line = const Color(0x1FC7DFE8),
      lineStrong = const Color(0x38C7DFE8),
      orbA = const Color(0x2491DDC5),
      orbB = const Color(0x268DB5FF),
      grid = const Color(0x08FFFFFF),
      shadow = const Color(0x59000000),
      heroFrame = const LinearGradient(
        colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      secondaryButton = const Color(0x05FFFFFF),
      iconWell = const Color(0xFF13242B);

  const _LandingPalette.light()
    : background = const Color(0xFFF7FBFD),
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FBFD), Color(0xFFEFF6FA)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      surface = const Color(0xC7FFFFFF),
      surfaceStrong = const Color(0xEBFFFFFF),
      text = const Color(0xFF10212D),
      muted = const Color(0xFF586B77),
      accent = const Color(0xFF0E9C78),
      line = const Color(0x1A102A38),
      lineStrong = const Color(0x2E102A38),
      orbA = const Color(0x1A0E9C78),
      orbB = const Color(0x1F6D93FF),
      grid = const Color(0x0C10212D),
      shadow = const Color(0x1F224153),
      heroFrame = const LinearGradient(
        colors: [Color(0xEBFFFFFF), Color(0xDBF4F9FC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      secondaryButton = const Color(0x85FFFFFF),
      iconWell = const Color(0xFFF0F6FA);

  final Color background;
  final Gradient backgroundGradient;
  final Color surface;
  final Color surfaceStrong;
  final Color text;
  final Color muted;
  final Color accent;
  final Color line;
  final Color lineStrong;
  final Color orbA;
  final Color orbB;
  final Color grid;
  final Color shadow;
  final Gradient heroFrame;
  final Color secondaryButton;
  final Color iconWell;
}
