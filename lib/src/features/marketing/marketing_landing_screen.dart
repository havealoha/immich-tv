import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../platform/browser_navigation.dart';
import '../../shared/presentation/app_colors.dart';

const _repoUrl = 'https://github.com/WorkWithAfridi/immich-tv';
const _issuesUrl = 'https://github.com/WorkWithAfridi/immich-tv/issues';
const _releasesUrl = 'https://github.com/WorkWithAfridi/immich-tv/releases';
const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.workwithafridi.immichtv';

const _proofPoints = <_ProofPoint>[
  _ProofPoint(value: '500+', label: 'Google Play installs'),
  _ProofPoint(value: '1.2.0', label: 'Current release line'),
  _ProofPoint(value: 'TV first', label: 'Android TV and Google TV'),
];

const _features = <_MarketingFeature>[
  _MarketingFeature(
    icon: Icons.tv_rounded,
    title: 'Made for the couch',
    body:
        'Large targets, predictable focus movement, and readable spacing keep remote navigation comfortable from across the room.',
  ),
  _MarketingFeature(
    icon: Icons.photo_library_outlined,
    title: 'Your Immich library',
    body:
        'Connect to your existing self-hosted server and browse timeline photos, albums, favorites, people, videos, and slideshows.',
  ),
  _MarketingFeature(
    icon: Icons.lock_outline_rounded,
    title: 'Read-only by design',
    body:
        'The app is focused on viewing and playback, so a shared living-room device can stay simple and low-risk.',
  ),
  _MarketingFeature(
    icon: Icons.devices_rounded,
    title: 'One Flutter codebase',
    body:
        'The public site, web entry, and native app now ship from the same project, which keeps product messaging and app behavior aligned.',
  ),
];

const _experienceItems = <_ExperienceItem>[
  _ExperienceItem(
    icon: Icons.calendar_month_rounded,
    title: 'Timeline by day',
    body: 'Browse recent memories with fast year jumps for large libraries.',
  ),
  _ExperienceItem(
    icon: Icons.play_circle_outline_rounded,
    title: 'Fullscreen playback',
    body: 'Open photos and videos with remote, keyboard, and pointer controls.',
  ),
  _ExperienceItem(
    icon: Icons.slideshow_rounded,
    title: 'Slideshow mode',
    body: 'Turn the TV into a simple ambient photo frame from the viewer.',
  ),
  _ExperienceItem(
    icon: Icons.account_circle_outlined,
    title: 'Saved profiles',
    body:
        'Return to family libraries quickly with local profiles and PIN unlock.',
  ),
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
        'Yes for normal use. Demo mode is included so testers can preview the flow without connecting a private library.',
  ),
  _FaqItem(
    question: 'Can I use it on the web?',
    answer:
        'The main web entry is available at /app. The product remains TV-first, and broader web use will continue to improve from the same Flutter project.',
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
                      'A living-room interface for your self-hosted library.',
                  body:
                      'Immich TV avoids stretched phone patterns and keeps the experience centered on browsing, playback, and remote control.',
                  child: _FeatureGrid(features: _features),
                ),
              ),
              SliverToBoxAdapter(
                child: _PageSection(
                  eyebrow: 'Core experience',
                  title: 'The viewing tools that matter on a shared screen.',
                  body:
                      'The app keeps the path from opening the library to enjoying photos and videos short, predictable, and readable.',
                  child: _ExperienceGrid(items: _experienceItems),
                ),
              ),
              SliverToBoxAdapter(
                child: _SplitSection(
                  leading: _ActionPanel(
                    icon: Icons.android_rounded,
                    eyebrow: 'Install',
                    title: 'Get the Android TV build.',
                    body:
                        'Install from Google Play for the public release, or use GitHub Releases for APK builds and release notes.',
                    primaryLabel: 'Open Google Play',
                    onPrimaryPressed: () => openExternalUrl(_playStoreUrl),
                    secondaryLabel: 'GitHub releases',
                    onSecondaryPressed: () => openExternalUrl(_releasesUrl),
                  ),
                  trailing: _ActionPanel(
                    icon: Icons.science_outlined,
                    eyebrow: 'Preview',
                    title: 'Try the demo flow.',
                    body:
                        'Demo mode appears only when the exact server URL below is entered during onboarding.',
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
                  title: 'Before you install.',
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

    return SizedBox(
      height: isCompact ? 680 : 760,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/png/banner.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xF2071014),
                  Color(0xCC071014),
                  Color(0x88071014),
                  Color(0xFF071014),
                ],
                stops: [0, 0.48, 0.74, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                      const Spacer(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              'A TV-first client for browsing your self-hosted Immich library from the couch.',
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
        _NavButton(
          icon: Icons.code_rounded,
          label: 'GitHub',
          onPressed: () => openExternalUrl(_repoUrl),
        ),
        const SizedBox(width: 8),
        _NavButton(
          icon: Icons.open_in_browser_rounded,
          label: 'Web app',
          onPressed: onOpenWebApp,
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
        decoration: BoxDecoration(
          color: _SiteColors.surface,
          border: Border.all(color: _SiteColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
              const SizedBox(height: 4),
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
      color: _SiteColors.page,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _SiteColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(feature.icon, color: _SiteColors.accent, size: 30),
              const SizedBox(height: 18),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _SiteColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: _SiteColors.accent, size: 22),
          ),
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
      decoration: BoxDecoration(
        color: _SiteColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SiteColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
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
      decoration: BoxDecoration(
        color: _SiteColors.band,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SiteColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
      color: _SiteColors.ink,
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
                            'Track the roadmap, audit the code, or contribute improvements.',
                            style: GoogleFonts.manrope(
                              color: _SiteColors.surface,
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
      decoration: BoxDecoration(
        color: _SiteColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SiteColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
        backgroundColor: AppColors.immichBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        foregroundColor: dark ? Colors.white : _SiteColors.ink,
        backgroundColor: dark
            ? Colors.white.withValues(alpha: 0.08)
            : _SiteColors.surface,
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.34)
              : _SiteColors.lineStrong,
        ),
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      tooltip: label,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
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

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _SiteColors {
  const _SiteColors._();

  static const page = Color(0xFF071014);
  static const band = Color(0xFF0D1A20);
  static const surface = Color(0xFF111F26);
  static const ink = Color(0xFFF4FAF8);
  static const muted = Color(0xFFA7B8BE);
  static const accent = Color(0xFF91DDC5);
  static const accentLight = Color(0xFF8FE3C6);
  static const accentSoft = Color(0xFF17352F);
  static const line = Color(0x263A555E);
  static const lineStrong = Color(0x667B929A);
}
