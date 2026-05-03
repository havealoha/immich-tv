import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/server_repository.dart';
import '../../shared/presentation/app_breakpoints.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/shortcut_hint.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _serverController = TextEditingController(
    text: 'http://192.168.0.243:2283',
  );
  final _emailController = TextEditingController(
    text: kDebugMode ? 'afridi.khondakar@gmail.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? "#Noobshit911" : '',
  );
  final _serverFieldFocusNode = FocusNode(debugLabel: 'serverField');
  final _emailFieldFocusNode = FocusNode(debugLabel: 'emailField');
  final _passwordFieldFocusNode = FocusNode(debugLabel: 'passwordField');
  final _actionButtonFocusNode = FocusNode(debugLabel: 'primaryAction');

  @override
  void dispose() {
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _serverFieldFocusNode.dispose();
    _emailFieldFocusNode.dispose();
    _passwordFieldFocusNode.dispose();
    _actionButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider(
      create: (_) => OnboardingCubit(
        authRepository: context.read<AuthRepository>(),
        serverRepository: context.read<ServerRepository>(),
      ),
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
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
                        viewportConstraints.maxWidth < AppBreakpoints.tablet ||
                        viewportConstraints.maxHeight < 700;

                    final form = _buildForm(context, theme, state);

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
                                child: SingleChildScrollView(child: form),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final panelHeight = (viewportConstraints.maxHeight - 64)
                        .clamp(560.0, 720.0);

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
                                      child: SingleChildScrollView(child: form),
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
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    OnboardingState state,
  ) {
    final isSubmitting = state.isBusy;
    final serverValidated = state.hasValidatedServer;
    final helperText = serverValidated
        ? 'Press Enter to sign in after entering your credentials.'
        : 'Press Enter to validate your server URL.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          serverValidated ? 'Sign in to Immich' : 'Connect your server',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          serverValidated
              ? 'We found a compatible Immich API. Sign in securely to continue.'
              : 'Start with the URL of your Immich instance. We will validate it before asking for credentials.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFB8C8CF),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _serverController,
          focusNode: _serverFieldFocusNode,
          enabled: !serverValidated && !isSubmitting,
          textInputAction: TextInputAction.done,
          onSubmitted: !serverValidated && !isSubmitting
              ? (_) => _handlePrimaryAction(context, state)
              : null,
          decoration: const InputDecoration(
            labelText: 'Immich server URL',
            hintText: 'https://photos.example.com',
          ),
        ),
        if (state.errorMessage case final message?) ...[
          const SizedBox(height: 18),
          _StatusBanner(
            icon: Icons.error_outline,
            color: const Color(0xFFFF907C),
            message: message,
          ),
        ],
        const SizedBox(height: 18),
        if (serverValidated) ...[
          _StatusBanner(
            icon: Icons.verified_outlined,
            color: const Color(0xFF6FE0DB),
            message:
                'API detected at ${state.serverConfig!.apiUrl}. Your session will be stored without saving the password.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailController,
            focusNode: _emailFieldFocusNode,
            enabled: !isSubmitting,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFieldFocusNode.requestFocus(),
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFieldFocusNode,
            enabled: !isSubmitting,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: !isSubmitting
                ? (_) => _handlePrimaryAction(context, state)
                : null,
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
        Row(
          children: [
            const ShortcutHint(label: 'Enter'),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                helperText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            focusNode: _actionButtonFocusNode,
            onPressed: isSubmitting
                ? null
                : () => _handlePrimaryAction(context, state),
            child: Text(
              isSubmitting
                  ? 'Working...'
                  : (serverValidated
                        ? 'Continue to library shell'
                        : 'Validate server'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    OnboardingState state,
  ) async {
    final onboardingCubit = context.read<OnboardingCubit>();
    final appFlowCubit = context.read<AppFlowCubit>();

    if (!state.hasValidatedServer) {
      await onboardingCubit.validateServer(_serverController.text);
      if (mounted) {
        _emailFieldFocusNode.requestFocus();
      }
      return;
    }

    final session = await onboardingCubit.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || session == null) {
      return;
    }

    appFlowCubit.completeSignIn(session);
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
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
            color: AppColors.backgroundElevated,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'MVP foundation',
            style: TextStyle(
              color: AppColors.focus,
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
            color: AppColors.textSecondary,
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
            color: AppColors.textMuted,
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
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.focus, size: 28),
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
                    color: AppColors.textSecondary,
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
