import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../platform/browser_navigation.dart';

const _repoUrl = 'https://github.com/WorkWithAfridi/immich-tv';
const _issuesUrl = 'https://github.com/WorkWithAfridi/immich-tv/issues';
const _releasesUrl = 'https://github.com/WorkWithAfridi/immich-tv/releases';
const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.workwithafridi.immichtv';

const _proofPoints = <_ProofPoint>[
  _ProofPoint(value: '500+', label: 'Public installs on Google Play'),
  _ProofPoint(value: '1.2.0', label: 'Current app release line'),
  _ProofPoint(
    value: 'TV-first',
    label: 'Built around Android TV and Google TV remotes',
  ),
];

const _features = <_MarketingFeature>[
  _MarketingFeature(
    icon: Icons.tv_rounded,
    title: 'Remote-first by default',
    body:
        'Directional navigation, large focus states, keyboard support, and pointer interaction are treated as primary inputs, not afterthoughts.',
  ),
  _MarketingFeature(
    icon: Icons.photo_library_outlined,
    title: 'A living-room Immich library',
    body:
        'Connect to the Immich server you already host and browse timeline photos, albums, people, favorites, videos, and slideshows.',
  ),
  _MarketingFeature(
    icon: Icons.lock_outline_rounded,
    title: 'Read-only shared-screen access',
    body:
        'Immich TV focuses on browsing and playback so household TVs stay simple, predictable, and low-risk.',
  ),
  _MarketingFeature(
    icon: Icons.smartphone_rounded,
    title: 'Phone-assisted text entry',
    body:
        'Scan a QR code during setup and use your phone for server URLs, email addresses, passwords, and API keys.',
  ),
];

const _experienceItems = <_ExperienceItem>[
  _ExperienceItem(
    icon: Icons.calendar_month_rounded,
    title: 'Timeline with year jumps',
    body:
        'Browse large libraries with paginated thumbnails, roomy rows, and a horizontal year rail for faster movement.',
  ),
  _ExperienceItem(
    icon: Icons.play_circle_outline_rounded,
    title: 'Fullscreen photo and video playback',
    body:
        'Open photos and videos with screen-safe metadata overlays and transport controls tuned for TV viewing.',
  ),
  _ExperienceItem(
    icon: Icons.slideshow_rounded,
    title: 'Slideshow playback',
    body:
        'Start a slideshow from the viewer, adjust duration, and pause or resume without leaving the remote-friendly flow.',
  ),
  _ExperienceItem(
    icon: Icons.account_circle_outlined,
    title: 'Saved profiles and PIN unlock',
    body:
        'Keep multiple household profiles available locally while secrets stay in platform secure storage where available.',
  ),
];

const _flowSteps = <_FlowStep>[
  _FlowStep(
    step: '01',
    title: 'Connect your server',
    body:
        'Enter your Immich server URL with reverse-proxy subpaths preserved and compatibility checked before sign-in.',
  ),
  _FlowStep(
    step: '02',
    title: 'Choose your sign-in method',
    body:
        'Use your Immich email and password or a personal API key, then save the profile for quick re-entry.',
  ),
  _FlowStep(
    step: '03',
    title: 'Browse from the couch',
    body:
        'Move between Timeline, Albums, People, Favorites, fullscreen viewing, and slideshow playback with a remote.',
  ),
];

const _platformItems = <_ExperienceItem>[
  _ExperienceItem(
    icon: Icons.android_rounded,
    title: 'Android TV and Google TV first',
    body:
        'The public Play Store build is the main installation path, with launcher and store polish still moving forward.',
  ),
  _ExperienceItem(
    icon: Icons.public_rounded,
    title: 'Web entry included',
    body:
        'The same Flutter project hosts the marketing site at / and the app entry at /app for browser-based previews.',
  ),
  _ExperienceItem(
    icon: Icons.speed_rounded,
    title: 'Performance remains a priority',
    body:
        'Thumbnail caching and prefetching have been tuned, with real-TV smoothness and degraded-network behavior next on the roadmap.',
  ),
  _ExperienceItem(
    icon: Icons.devices_rounded,
    title: 'Broader Flutter targets',
    body:
        'Android, web, Windows, macOS, and Linux builds remain supported for development and validation.',
  ),
];

const _faqItems = <_FaqItem>[
  _FaqItem(
    question: 'What is Immich TV?',
    answer:
        'Immich TV is an open source, TV-first Flutter client for browsing a self-hosted Immich photo and video library on Android TV and Google TV.',
  ),
  _FaqItem(
    question: 'Do I need my own Immich server?',
    answer:
        'Yes for normal use. A built-in demo path is available so you can preview the onboarding and browsing flow before connecting a private library.',
  ),
  _FaqItem(
    question: 'Is Immich TV available on Google Play?',
    answer:
        'Yes. The Android TV app is published on Google Play, and APK releases are also available from GitHub for manual installation.',
  ),
  _FaqItem(
    question: 'Why does the site mention typing on my phone?',
    answer:
        'Long text entry is painful with a TV remote. Immich TV can show a QR code so a phone can type into the currently focused TV field during setup.',
  ),
  _FaqItem(
    question: 'Is this an official Immich app?',
    answer:
        'No. Immich TV is an independent client project for people who already run or can access an Immich server.',
  ),
];

class MarketingLandingScreen extends StatelessWidget {
  const MarketingLandingScreen({super.key, required this.onOpenWebApp});

  final VoidCallback onOpenWebApp;

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.manropeTextTheme();

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _SiteColors.page,
        textTheme: textTheme.apply(
          bodyColor: _SiteColors.ink,
          displayColor: _SiteColors.ink,
        ),
      ),
      child: Scaffold(
        body: SelectionArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Hero(onOpenWebApp: onOpenWebApp)),
              const SliverToBoxAdapter(child: _ProofBand()),
              SliverToBoxAdapter(
                child: _PageSection(
                  eyebrow: 'Why Immich TV',
                  title:
                      'A modern TV interface for the library you already host.',
                  body:
                      'Immich TV is designed around focus, distance, low-friction setup, and shared-screen comfort instead of shrinking a phone or desktop layout onto the television.',
                  child: _FeatureGrid(features: _features),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageSection(
                  eyebrow: 'Core experience',
                  title:
                      'Everything you need to browse and play back memories.',
                  body:
                      'Timeline browsing, collections, people, favorites, media playback, and slideshows are kept direct and readable on large screens.',
                  child: _ExperienceGrid(items: _experienceItems),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageSection(
                  eyebrow: 'How it works',
                  title: 'Connect once, then keep the remote in your hand.',
                  body:
                      'Immich TV validates your server, supports both account and API-key sign-in, and keeps saved profiles ready for the next viewing session.',
                  child: _FlowStepGrid(steps: _flowSteps),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageSection(
                  eyebrow: 'Status',
                  title:
                      'Available now, with the roadmap focused on TV polish.',
                  body:
                      'The app is already usable as a focused read-only Immich client, while active work continues on real-device performance, degraded-network resilience, and release readiness.',
                  child: _ExperienceGrid(items: _platformItems),
                ),
              ),
              SliverToBoxAdapter(
                child: _SplitSection(
                  leading: _ActionPanel(
                    icon: Icons.android_rounded,
                    eyebrow: 'Install',
                    title:
                        'Install from Google Play or follow GitHub releases.',
                    body:
                        'Google Play is the simplest path for Android TV and Google TV. GitHub releases remain available for manual installs, release notes, and source inspection.',
                    primaryLabel: 'Open Google Play',
                    onPrimaryPressed: () => openExternalUrl(_playStoreUrl),
                    secondaryLabel: 'GitHub releases',
                    onSecondaryPressed: () => openExternalUrl(_releasesUrl),
                  ),
                  trailing: _ActionPanel(
                    icon: Icons.science_outlined,
                    eyebrow: 'Preview',
                    title: 'Try the web app flow before connecting a server.',
                    body:
                        'A demo mode is included for walkthroughs and testing. Enter the exact server URL below during onboarding to unlock the preview library.',
                    primaryLabel: 'Open web app',
                    onPrimaryPressed: onOpenWebApp,
                    content: const _DemoCredentials(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _RepositoryBand(
                  onOpenRepo: () => openExternalUrl(_repoUrl),
                  onOpenIssues: () => openExternalUrl(_issuesUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageSection(
                  eyebrow: 'FAQ',
                  title: 'What people usually want to know first.',
                  child: _FaqList(items: _faqItems),
                ),
              ),
              const SliverToBoxAdapter(child: _Footer()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onOpenWebApp});

  final VoidCallback onOpenWebApp;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isCompact ? 920 : 820),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/png/banner.png', fit: BoxFit.cover),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF050C10),
                    Color(0xF2071014),
                    Color(0xD9071014),
                    Color(0xFF071014),
                  ],
                  stops: [0, 0.24, 0.58, 1],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 18 : 40,
                18,
                isCompact ? 18 : 40,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1160),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(onOpenWebApp: onOpenWebApp),
                      SizedBox(height: isCompact ? 82 : 160),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _HeroTag(
                              text: 'Now on Google Play for Android TV',
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Immich TV',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: isCompact ? 56 : 84,
                                height: 1.02,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'A TV-first client for browsing your self-hosted Immich photo and video library from the couch.',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFFE8F1EF),
                                fontSize: isCompact ? 19 : 24,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 26),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _PrimaryButton(
                                  icon: Icons.android_rounded,
                                  label: 'Get it on Google Play',
                                  onPressed: () =>
                                      openExternalUrl(_playStoreUrl),
                                ),
                                _SecondaryButton(
                                  icon: Icons.open_in_browser_rounded,
                                  label: 'Open web app',
                                  onPressed: onOpenWebApp,
                                  dark: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: const _HeroHighlightCard(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenWebApp});

  final VoidCallback onOpenWebApp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/png/playstore.png',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Immich TV',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _NavButton(
              icon: Icons.code_rounded,
              label: 'GitHub',
              onPressed: () => openExternalUrl(_repoUrl),
            ),
            _NavButton(
              icon: Icons.open_in_browser_rounded,
              label: 'Web app',
              onPressed: onOpenWebApp,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProofBand extends StatelessWidget {
  const _ProofBand();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _SiteColors.page,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 42),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnWidth = constraints.maxWidth < 720
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 2) / 3;
                return Wrap(
                  spacing: 1,
                  runSpacing: 1,
                  children: _proofPoints
                      .map(
                        (point) => _ProofTile(point: point, width: columnWidth),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.point, required this.width});

  final _ProofPoint point;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: _SiteColors.lineStrong),
            bottom: BorderSide(color: _SiteColors.line),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.value,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _SiteColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                point.label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _SiteColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSection extends StatelessWidget {
  const _PageSection({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _SiteColors.section,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 42, 18, 58),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(eyebrow: eyebrow, title: title, body: body),
                const SizedBox(height: 26),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.title, this.body});

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: GoogleFonts.manrope(
              color: _SiteColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              color: _SiteColors.ink,
              fontSize: MediaQuery.sizeOf(context).width < 720 ? 32 : 44,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 14),
            Text(
              body!,
              style: GoogleFonts.manrope(
                color: _SiteColors.muted,
                fontSize: 17,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<_MarketingFeature> features;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: features
              .map((feature) => _FeatureCard(feature: feature, width: width))
              .toList(growable: false),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.width});

  final _MarketingFeature feature;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _SiteColors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 22, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(feature.icon, color: _SiteColors.accent, size: 30),
              const SizedBox(height: 20),
              Text(
                feature.title,
                style: GoogleFonts.manrope(
                  color: _SiteColors.ink,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                feature.body,
                style: GoogleFonts.manrope(
                  color: _SiteColors.muted,
                  fontSize: 15,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowStepGrid extends StatelessWidget {
  const _FlowStepGrid({required this.steps});

  final List<_FlowStep> steps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: steps
              .map((step) => _FlowStepCard(step: step, width: width))
              .toList(growable: false),
        );
      },
    );
  }
}

class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({required this.step, required this.width});

  final _FlowStep step;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _SiteColors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.step,
                style: GoogleFonts.manrope(
                  color: _SiteColors.accentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                step.title,
                style: GoogleFonts.manrope(
                  color: _SiteColors.ink,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.body,
                style: GoogleFonts.manrope(
                  color: _SiteColors.muted,
                  fontSize: 15,
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperienceGrid extends StatelessWidget {
  const _ExperienceGrid({required this.items});

  final List<_ExperienceItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items
              .map(
                (item) => _ExperienceRow(
                  item: item,
                  width: isWide
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ExperienceRow extends StatelessWidget {
  const _ExperienceRow({required this.item, required this.width});

  final _ExperienceItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: _SiteColors.accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.manrope(
                    color: _SiteColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  style: GoogleFonts.manrope(
                    color: _SiteColors.muted,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitSection extends StatelessWidget {
  const _SplitSection({required this.leading, required this.trailing});

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _SiteColors.band,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 58, 18, 58),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth,
                      child: leading,
                    ),
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth,
                      child: trailing,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.content,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _SiteColors.lineStrong),
          bottom: BorderSide(color: _SiteColors.line),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _SiteColors.accent, size: 34),
            const SizedBox(height: 18),
            Text(
              eyebrow.toUpperCase(),
              style: GoogleFonts.manrope(
                color: _SiteColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.manrope(
                color: _SiteColors.ink,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: GoogleFonts.manrope(
                color: _SiteColors.muted,
                fontSize: 16,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (content != null) ...[const SizedBox(height: 20), content!],
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PrimaryButton(
                  icon: Icons.arrow_forward_rounded,
                  label: primaryLabel,
                  onPressed: onPrimaryPressed,
                ),
                if (secondaryLabel != null && onSecondaryPressed != null)
                  _SecondaryButton(
                    icon: Icons.open_in_new_rounded,
                    label: secondaryLabel!,
                    onPressed: onSecondaryPressed!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _SiteColors.line),
          bottom: BorderSide(color: _SiteColors.line),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: const [
            _CredentialLine(
              label: 'Server URL',
              value: 'https://demo.immichtv.local',
            ),
            Divider(height: 22, color: _SiteColors.line),
            _CredentialLine(label: 'Email', value: 'demo@immich.tv'),
            Divider(height: 22, color: _SiteColors.line),
            _CredentialLine(label: 'Password', value: 'demo1234'),
          ],
        ),
      ),
    );
  }
}

class _CredentialLine extends StatelessWidget {
  const _CredentialLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: _SiteColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: GoogleFonts.manrope(
              color: _SiteColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RepositoryBand extends StatelessWidget {
  const _RepositoryBand({required this.onOpenRepo, required this.onOpenIssues});

  final VoidCallback onOpenRepo;
  final VoidCallback onOpenIssues;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _SiteColors.band,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 48, 18, 48),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                return Wrap(
                  spacing: 22,
                  runSpacing: 22,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isWide ? 620 : constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open source',
                            style: GoogleFonts.manrope(
                              color: _SiteColors.accentLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Follow the roadmap, inspect the code, and help shape a focused TV client for Immich.',
                            style: GoogleFonts.manrope(
                              color: _SiteColors.ink,
                              fontSize: 34,
                              height: 1.16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SecondaryButton(
                          icon: Icons.code_rounded,
                          label: 'Open repo',
                          onPressed: onOpenRepo,
                          dark: true,
                        ),
                        _SecondaryButton(
                          icon: Icons.bug_report_outlined,
                          label: 'Report issue',
                          onPressed: onOpenIssues,
                          dark: true,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({required this.items});

  final List<_FaqItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FaqTile(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _SiteColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.question,
              style: GoogleFonts.manrope(
                color: _SiteColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.answer,
              style: GoogleFonts.manrope(
                color: _SiteColors.muted,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _SiteColors.page,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 44),
            child: Text(
              'Immich TV is an independent client project and is not an official Immich app.',
              style: GoogleFonts.manrope(
                color: _SiteColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _SiteColors.accent,
        foregroundColor: _SiteColors.page,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? _SiteColors.ink : _SiteColors.ink,
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: dark ? _SiteColors.lineStrong : _SiteColors.lineStrong,
        ),
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Tooltip(
      message: label,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: compact ? const SizedBox.shrink() : Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _SiteColors.ink,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: _SiteColors.lineStrong),
          minimumSize: const Size(0, 46),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: 12,
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _SiteColors.lineStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          style: GoogleFonts.manrope(
            color: const Color(0xFFE9F7F1),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _HeroHighlightCard extends StatelessWidget {
  const _HeroHighlightCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _SiteColors.lineStrong)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Wrap(
          spacing: 18,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            _HeroHighlightItem(
              icon: Icons.phone_iphone_rounded,
              title: 'No remote-keyboard struggle',
              body:
                  'Scan a setup QR code and type server details or credentials from your phone.',
            ),
            _HeroHighlightItem(
              icon: Icons.dvr_rounded,
              title: 'Read-only by design',
              body:
                  'Browse, play, and present memories without turning the shared TV into a library-management device.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHighlightItem extends StatelessWidget {
  const _HeroHighlightItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _SiteColors.accentLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFD5E4E0),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofPoint {
  const _ProofPoint({required this.value, required this.label});

  final String value;
  final String label;
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

class _ExperienceItem {
  const _ExperienceItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _FlowStep {
  const _FlowStep({
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _SiteColors {
  const _SiteColors._();

  static const page = Color(0xFF071014);
  static const section = Color(0xFF081216);
  static const band = Color(0xFF0B171C);
  static const ink = Color(0xFFF4FAF8);
  static const muted = Color(0xFFA7B8BE);
  static const accent = Color(0xFF91DDC5);
  static const accentLight = Color(0xFF8FE3C6);
  static const line = Color(0x263A555E);
  static const lineStrong = Color(0x667B929A);
}
