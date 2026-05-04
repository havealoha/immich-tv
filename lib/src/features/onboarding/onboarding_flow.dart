import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_environment.dart';
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
    text: "http://192.168.0.243:2283",
  );
  final _emailController = TextEditingController(
    text: "afridi.khondakar@gmail.com",
  );
  final _passwordController = TextEditingController(text: "#Noobshit911");
  final _serverFieldFocusNode = FocusNode(debugLabel: 'serverField');
  final _emailFieldFocusNode = FocusNode(debugLabel: 'emailField');
  final _passwordFieldFocusNode = FocusNode(debugLabel: 'passwordField');
  final _actionButtonFocusNode = FocusNode(debugLabel: 'primaryAction');
  bool _hasAppliedInitialValues = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAppliedInitialValues) {
      return;
    }

    final environment = context.read<AppEnvironment>();
    final useMockServices = environment.useMockServices;

    _serverController.text = useMockServices
        ? 'https://demo.immichtv.local'
        : 'http://192.168.0.243:2283';
    _emailController.text = useMockServices
        ? 'livingroom@demo.immichtv'
        : 'afridi.khondakar@gmail.com';
    _passwordController.text = useMockServices
        ? 'demo-password'
        : '#Noobshit911';
    _hasAppliedInitialValues = true;
  }

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
                    final isTvLayout =
                        viewportConstraints.maxWidth >= AppBreakpoints.tv;
                    final horizontalPadding = isTvLayout
                        ? 56.0
                        : viewportConstraints.maxWidth < AppBreakpoints.tablet
                        ? 24.0
                        : 32.0;
                    final cardMaxWidth = isTvLayout ? 760.0 : 560.0;
                    final cardPadding = isTvLayout ? 40.0 : 32.0;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24,
                      ),
                      child: Column(
                        children: [
                          _TopBranding(
                            theme: theme,
                            state: state,
                            isTvLayout: isTvLayout,
                          ),
                          SizedBox(height: isTvLayout ? 48 : 32),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: cardMaxWidth,
                                ),
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(cardPadding),
                                    child: SingleChildScrollView(
                                      child: _buildForm(
                                        context,
                                        theme,
                                        state,
                                        isTvLayout: isTvLayout,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    OnboardingState state, {
    required bool isTvLayout,
  }) {
    final useMockServices = context.read<AppEnvironment>().useMockServices;
    final isSubmitting = state.isBusy;
    final serverValidated = state.hasValidatedServer;
    final helperText = serverValidated
        ? 'Press Enter to sign in after entering your credentials.'
        : 'Press Enter to validate your server URL.';
    final titleStyle =
        (isTvLayout
                ? theme.textTheme.headlineLarge
                : theme.textTheme.headlineMedium)
            ?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle =
        (isTvLayout ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
            ?.copyWith(color: const Color(0xFFB8C8CF), height: 1.5);
    final fieldSpacing = isTvLayout ? 24.0 : 18.0;
    final contentGap = isTvLayout ? 36.0 : 28.0;
    final buttonHeight = isTvLayout ? 64.0 : 52.0;
    final statusPadding = isTvLayout ? 20.0 : 16.0;

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTvLayout ? 24 : 18,
            vertical: isTvLayout ? 22 : 18,
          ),
          labelStyle: isTvLayout ? theme.textTheme.titleMedium : null,
          hintStyle: isTvLayout
              ? theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                )
              : null,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: isTvLayout
            ? theme.textTheme.titleMedium ?? const TextStyle()
            : theme.textTheme.bodyLarge ?? const TextStyle(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serverValidated ? 'Sign in to Immich' : 'Connect your server',
              style: titleStyle,
            ),
            const SizedBox(height: 12),
            Text(
              serverValidated
                  ? (useMockServices
                        ? 'Demo mode is active. Sign in to explore the curated TV experience with mock content.'
                        : 'We found a compatible Immich API. Sign in securely to continue.')
                  : (useMockServices
                        ? 'Start with the demo server URL. We will validate it and load a polished mock library so we can shape the full TV experience first.'
                        : 'Start with the URL of your Immich instance. We will validate it before asking for credentials.'),
              style: bodyStyle,
            ),
            SizedBox(height: contentGap),
            if (useMockServices) ...[
              _StatusBanner(
                icon: Icons.auto_awesome_outlined,
                color: const Color(0xFF6FE0DB),
                message:
                    'Demo mode is on. Authentication, library browsing, pagination, and fullscreen viewing are currently backed by mock data so we can polish the UI before real API rollout.',
                padding: statusPadding,
                isTvLayout: isTvLayout,
              ),
              SizedBox(height: fieldSpacing),
            ],
            TextField(
              controller: _serverController,
              focusNode: _serverFieldFocusNode,
              enabled: !serverValidated && !isSubmitting,
              textInputAction: TextInputAction.done,
              style: isTvLayout ? theme.textTheme.titleLarge : null,
              onSubmitted: !serverValidated && !isSubmitting
                  ? (_) => _handlePrimaryAction(context, state)
                  : null,
              decoration: const InputDecoration(
                labelText: 'Immich server URL',
                hintText: 'https://photos.example.com',
              ),
            ),
            if (state.errorMessage case final message?) ...[
              SizedBox(height: fieldSpacing),
              _StatusBanner(
                icon: Icons.error_outline,
                color: const Color(0xFFFF907C),
                message: message,
                padding: statusPadding,
                isTvLayout: isTvLayout,
              ),
            ],
            if (serverValidated) ...[
              SizedBox(height: fieldSpacing),
              _StatusBanner(
                icon: Icons.verified_outlined,
                color: const Color(0xFF6FE0DB),
                message: useMockServices
                    ? 'Demo server ready at ${state.serverConfig!.apiUrl}. Your mock session will restore like a real TV app flow.'
                    : 'API detected at ${state.serverConfig!.apiUrl}. Your session will be stored without saving the password.',
                padding: statusPadding,
                isTvLayout: isTvLayout,
              ),
              SizedBox(height: fieldSpacing),
              TextField(
                controller: _emailController,
                focusNode: _emailFieldFocusNode,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                style: isTvLayout ? theme.textTheme.titleLarge : null,
                onSubmitted: (_) => _passwordFieldFocusNode.requestFocus(),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: fieldSpacing),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFieldFocusNode,
                enabled: !isSubmitting,
                obscureText: true,
                style: isTvLayout ? theme.textTheme.titleLarge : null,
                textInputAction: TextInputAction.done,
                onSubmitted: !isSubmitting
                    ? (_) => _handlePrimaryAction(context, state)
                    : null,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
            SizedBox(height: isTvLayout ? 28 : 24),
            Row(
              children: [
                ShortcutHint(
                  label: 'Enter',
                  size: isTvLayout
                      ? ShortcutHintSize.large
                      : ShortcutHintSize.medium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    helperText,
                    style:
                        (isTvLayout
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.bodyMedium)
                            ?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTvLayout ? 24 : 18),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: FilledButton(
                focusNode: _actionButtonFocusNode,
                style: FilledButton.styleFrom(
                  textStyle: isTvLayout
                      ? theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )
                      : theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                ),
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
        ),
      ),
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
    required this.padding,
    required this.isTvLayout,
  });

  final IconData icon;
  final Color color;
  final String message;
  final double padding;
  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isTvLayout ? 28 : 24),
          SizedBox(width: isTvLayout ? 16 : 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: isTvLayout ? 18 : null,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBranding extends StatelessWidget {
  const _TopBranding({
    required this.theme,
    required this.state,
    required this.isTvLayout,
  });

  final ThemeData theme;
  final OnboardingState state;
  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    final serverValidated = state.hasValidatedServer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Immich TV',
          textAlign: TextAlign.center,
          style:
              (isTvLayout
                      ? theme.textTheme.displayMedium
                      : theme.textTheme.displaySmall)
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1),
        ),
        SizedBox(height: isTvLayout ? 18 : 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTvLayout ? 960 : 760),
          child: Text(
            serverValidated
                ? 'Your server is ready. Enter your Immich account email and password to continue.'
                : 'Enter your Immich Server URL to connect this TV and continue to sign in.',
            textAlign: TextAlign.center,
            style:
                (isTvLayout
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }
}
