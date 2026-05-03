import 'package:flutter/material.dart';

import '../../app_shell.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onAuthenticated});

  final ValueChanged<AppSession> onAuthenticated;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _serverController = TextEditingController(
    text: 'https://photos.example.com',
  );
  final _emailController = TextEditingController(text: 'family@example.com');
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _serverValidated = false;

  @override
  void dispose() {
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _validateServer() async {
    setState(() {
      _isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    setState(() {
      _serverValidated = true;
      _isSubmitting = false;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) {
      return;
    }

    widget.onAuthenticated(
      AppSession(
        serverUrl: _normalizedServerUrl,
        userEmail: _emailController.text.trim(),
        displayName: 'Living Room',
      ),
    );
  }

  String get _normalizedServerUrl =>
      _serverController.text.trim().replaceAll(RegExp(r'/$'), '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A4E58), Color(0xFF08131A)],
            center: Alignment.topLeft,
            radius: 1.4,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final useCompactLayout =
                  viewportConstraints.maxWidth < 900 ||
                  viewportConstraints.maxHeight < 700;

              if (useCompactLayout) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: SingleChildScrollView(
                            child: _IntroPanel(theme: theme),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: SingleChildScrollView(child: _buildForm(theme)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final panelHeight = (viewportConstraints.maxHeight - 64).clamp(
                560.0,
                720.0,
              );

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      height: panelHeight.toDouble(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: SingleChildScrollView(
                                  child: _IntroPanel(theme: theme),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: SingleChildScrollView(
                                  child: _buildForm(theme),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _serverValidated ? 'Sign in to Immich' : 'Connect your server',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _serverValidated
              ? 'We found your server. The next step is a secure sign in for the TV session.'
              : 'Start with the URL of your Immich instance. We will validate it before asking for credentials.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFB8C8CF),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _serverController,
          enabled: !_serverValidated && !_isSubmitting,
          decoration: const InputDecoration(
            labelText: 'Immich server URL',
            hintText: 'https://photos.example.com',
          ),
        ),
        const SizedBox(height: 18),
        if (_serverValidated) ...[
          TextField(
            controller: _emailController,
            enabled: !_isSubmitting,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            enabled: !_isSubmitting,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E3947)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF6FE0DB),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Next up: real API validation, secure storage, and persisted sessions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB8C8CF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting
                ? null
                : (_serverValidated ? _signIn : _validateServer),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF6FE0DB),
              foregroundColor: const Color(0xFF062227),
            ),
            child: Text(
              _isSubmitting
                  ? 'Working...'
                  : (_serverValidated
                        ? 'Continue to library shell'
                        : 'Validate server'),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF1E3947)),
          ),
          child: const Text(
            'MVP foundation',
            style: TextStyle(
              color: Color(0xFF6FE0DB),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'A TV-first Immich client for the living room.',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'This first milestone focuses on the core path: app bootstrap, server entry, authentication handoff, and a library shell ready for albums, timeline, favorites, and slideshow work.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFB8C8CF),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        const _FeatureCallout(
          icon: Icons.dns_outlined,
          title: 'Server-first onboarding',
          body: 'Validate the user server before asking for credentials.',
        ),
        const SizedBox(height: 16),
        const _FeatureCallout(
          icon: Icons.settings_remote_outlined,
          title: 'TV-friendly navigation',
          body:
              'Large cards, calm contrast, and layouts that translate well to remote input.',
        ),
        const SizedBox(height: 16),
        const _FeatureCallout(
          icon: Icons.photo_library_outlined,
          title: 'Library-focused roadmap',
          body:
              'Timeline, albums, favorites, slideshow, caching, and session persistence come next.',
        ),
        const SizedBox(height: 24),
        Text(
          'Today we are replacing the starter app with product-shaped structure so feature work has a clean home.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF7FA2AF),
          ),
        ),
      ],
    );
  }
}

class _FeatureCallout extends StatelessWidget {
  const _FeatureCallout({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3947)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6FE0DB), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB8C8CF),
                    height: 1.5,
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
