import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/shortcut_hint.dart';
import '../cubit/onboarding_state.dart';
import 'onboarding_status_banner.dart';

class OnboardingForm extends StatelessWidget {
  const OnboardingForm({
    super.key,
    required this.theme,
    required this.state,
    required this.isTvLayout,
    required this.useMockServices,
    required this.hasSavedProfiles,
    required this.serverController,
    required this.emailController,
    required this.passwordController,
    required this.pinController,
    required this.confirmPinController,
    required this.serverFieldFocusNode,
    required this.emailFieldFocusNode,
    required this.passwordFieldFocusNode,
    required this.pinFieldFocusNode,
    required this.confirmPinFieldFocusNode,
    required this.actionButtonFocusNode,
    required this.onPrimaryAction,
    required this.onShowProfiles,
  });

  final ThemeData theme;
  final OnboardingState state;
  final bool isTvLayout;
  final bool useMockServices;
  final bool hasSavedProfiles;
  final TextEditingController serverController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController pinController;
  final TextEditingController confirmPinController;
  final FocusNode serverFieldFocusNode;
  final FocusNode emailFieldFocusNode;
  final FocusNode passwordFieldFocusNode;
  final FocusNode pinFieldFocusNode;
  final FocusNode confirmPinFieldFocusNode;
  final FocusNode actionButtonFocusNode;
  final VoidCallback onPrimaryAction;
  final VoidCallback onShowProfiles;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.isBusy;
    final serverValidated = state.hasValidatedServer;
    final helperText = serverValidated
        ? 'Press Enter to save this profile after entering credentials and a 4-digit PIN.'
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
              serverValidated
                  ? 'Create a saved profile'
                  : 'Connect your server',
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
              OnboardingStatusBanner(
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
              controller: serverController,
              focusNode: serverFieldFocusNode,
              enabled: !serverValidated && !isSubmitting,
              textInputAction: TextInputAction.done,
              style: isTvLayout ? theme.textTheme.titleLarge : null,
              onSubmitted: !serverValidated && !isSubmitting
                  ? (_) => onPrimaryAction()
                  : null,
              decoration: const InputDecoration(
                labelText: 'Immich server URL',
                hintText: 'https://photos.example.com',
              ),
            ),
            if (state.errorMessage case final message?) ...[
              SizedBox(height: fieldSpacing),
              OnboardingStatusBanner(
                icon: Icons.error_outline,
                color: const Color(0xFFFF907C),
                message: message,
                padding: statusPadding,
                isTvLayout: isTvLayout,
              ),
            ],
            if (serverValidated) ...[
              SizedBox(height: fieldSpacing),
              OnboardingStatusBanner(
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
                controller: emailController,
                focusNode: emailFieldFocusNode,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                style: isTvLayout ? theme.textTheme.titleLarge : null,
                onSubmitted: (_) => passwordFieldFocusNode.requestFocus(),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: fieldSpacing),
              TextField(
                controller: passwordController,
                focusNode: passwordFieldFocusNode,
                enabled: !isSubmitting,
                obscureText: true,
                style: isTvLayout ? theme.textTheme.titleLarge : null,
                textInputAction: TextInputAction.next,
                onSubmitted: !isSubmitting
                    ? (_) => pinFieldFocusNode.requestFocus()
                    : null,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: fieldSpacing),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pinController,
                      focusNode: pinFieldFocusNode,
                      enabled: !isSubmitting,
                      obscureText: true,
                      style: isTvLayout ? theme.textTheme.titleLarge : null,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onSubmitted: (_) =>
                          confirmPinFieldFocusNode.requestFocus(),
                      decoration: const InputDecoration(
                        labelText: '4-digit PIN',
                      ),
                    ),
                  ),
                  SizedBox(width: fieldSpacing),
                  Expanded(
                    child: TextField(
                      controller: confirmPinController,
                      focusNode: confirmPinFieldFocusNode,
                      enabled: !isSubmitting,
                      obscureText: true,
                      style: isTvLayout ? theme.textTheme.titleLarge : null,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onSubmitted: !isSubmitting
                          ? (_) => onPrimaryAction()
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: fieldSpacing),
              Text(
                'This PIN unlocks the saved profile on future launches without re-entering your Immich email and password.',
                style:
                    (isTvLayout
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(color: AppColors.textMuted, height: 1.5),
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
                focusNode: actionButtonFocusNode,
                style: FilledButton.styleFrom(
                  textStyle: isTvLayout
                      ? theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )
                      : theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                ),
                onPressed: isSubmitting ? null : onPrimaryAction,
                child: Text(
                  isSubmitting
                      ? 'Working...'
                      : (serverValidated
                            ? 'Save profile and continue'
                            : 'Validate server'),
                ),
              ),
            ),
            if (hasSavedProfiles) ...[
              SizedBox(height: isTvLayout ? 16 : 12),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onShowProfiles,
                  child: const Text('Back to profiles'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
