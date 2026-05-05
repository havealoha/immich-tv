import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/app_colors.dart';
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
    required this.onSecondaryAction,
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
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.isBusy;
    final isServerStep = state.step == OnboardingStep.server;
    final isCredentialsStep = state.step == OnboardingStep.credentials;
    final helperText = switch (state.step) {
      OnboardingStep.server => 'Press Enter to validate your server URL and continue.',
      OnboardingStep.credentials => 'Press Enter to sign in and continue to PIN setup.',
      OnboardingStep.pin => 'Press Enter to save this profile after entering your 4-digit PIN.',
    };
    final title = switch (state.step) {
      OnboardingStep.server => 'Connect your server',
      OnboardingStep.credentials => 'Sign in to Immich',
      OnboardingStep.pin => 'Create a profile PIN',
    };
    final description = switch (state.step) {
      OnboardingStep.server =>
        useMockServices
            ? 'Start with the demo server URL. We will validate it and load a polished mock library so we can shape the full TV experience first.'
            : 'Start with the URL of your Immich instance. We will validate it before asking for credentials.',
      OnboardingStep.credentials =>
        useMockServices
            ? 'Demo mode is active. Enter your Immich account details to create a TV-ready mock session.'
            : 'Your server is verified. Sign in with your Immich account to continue.',
      OnboardingStep.pin =>
        useMockServices
            ? 'Your mock session is ready. Add a 4-digit PIN so this TV profile can be reopened quickly.'
            : 'You are signed in. Add a 4-digit PIN so this TV profile can be reopened without entering your password again.',
    };
    final primaryButtonLabel = switch (state.step) {
      OnboardingStep.server => 'Validate server',
      OnboardingStep.credentials => 'Continue to PIN setup',
      OnboardingStep.pin => 'Save profile and continue',
    };
    final secondaryButtonLabel = switch (state.step) {
      OnboardingStep.server => 'Back to profiles',
      OnboardingStep.credentials => 'Change server',
      OnboardingStep.pin => 'Back to sign in',
    };
    final titleStyle = (isTvLayout ? theme.textTheme.headlineLarge : theme.textTheme.headlineMedium)?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = (isTvLayout ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)?.copyWith(color: const Color(0xFFB8C8CF), height: 1.5);
    final fieldSpacing = isTvLayout ? 18.0 : 18.0;
    final contentGap = isTvLayout ? 24.0 : 28.0;
    final buttonHeight = isTvLayout ? 60.0 : 52.0;
    final statusPadding = isTvLayout ? 16.0 : 16.0;
    final buttonTextStyle = (isTvLayout ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.w700, height: 1.1);

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          contentPadding: EdgeInsets.symmetric(horizontal: isTvLayout ? 18 : 18, vertical: isTvLayout ? 16 : 18),
          labelStyle: isTvLayout ? theme.textTheme.titleSmall : null,
          hintStyle: isTvLayout ? theme.textTheme.titleSmall?.copyWith(color: AppColors.textMuted) : null,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: isTvLayout ? theme.textTheme.bodyLarge ?? const TextStyle() : theme.textTheme.bodyLarge ?? const TextStyle(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            SizedBox(height: isTvLayout ? 8 : 12),
            // Text(description, style: bodyStyle),
            // SizedBox(height: contentGap),
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
            if (state.errorMessage case final message?) ...[
              if (!useMockServices) SizedBox(height: fieldSpacing),
              OnboardingStatusBanner(
                icon: Icons.error_outline,
                color: const Color(0xFFFF907C),
                message: message,
                padding: statusPadding,
                isTvLayout: isTvLayout,
              ),
            ],
            if (isServerStep) ...[
              TextField(
                controller: serverController,
                focusNode: serverFieldFocusNode,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.done,
                style: isTvLayout ? theme.textTheme.titleMedium : null,
                onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                decoration: const InputDecoration(labelText: 'Immich server URL', hintText: 'https://photos.example.com'),
              ),
            ] else if (isCredentialsStep) ...[
              // SizedBox(height: fieldSpacing),
              // OnboardingStatusBanner(
              //   icon: Icons.verified_outlined,
              //   color: const Color(0xFF6FE0DB),
              //   message: useMockServices
              //       ? 'Demo server ready at ${state.serverConfig!.apiUrl}. Your mock session will restore like a real TV app flow.'
              //       : 'API detected at ${state.serverConfig!.apiUrl}. Your session will be stored without saving the password.',
              //   padding: statusPadding,
              //   isTvLayout: isTvLayout,
              // ),
              // SizedBox(height: fieldSpacing),
              TextField(
                controller: emailController,
                focusNode: emailFieldFocusNode,
                enabled: !isSubmitting,
                textInputAction: TextInputAction.next,
                style: isTvLayout ? theme.textTheme.titleMedium : null,
                onSubmitted: (_) => passwordFieldFocusNode.requestFocus(),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: fieldSpacing),
              TextField(
                controller: passwordController,
                focusNode: passwordFieldFocusNode,
                enabled: !isSubmitting,
                obscureText: true,
                style: isTvLayout ? theme.textTheme.titleMedium : null,
                textInputAction: TextInputAction.next,
                onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ] else ...[
              // SizedBox(height: fieldSpacing),
              // OnboardingStatusBanner(
              //   icon: Icons.lock_outline_rounded,
              //   color: const Color(0xFF6FE0DB),
              //   message: state.pendingSession == null
              //       ? 'Complete sign-in before saving this TV profile.'
              //       : 'Signed in as ${state.pendingSession!.user.email}. Choose a 4-digit PIN for quick access on this TV.',
              //   padding: statusPadding,
              //   isTvLayout: isTvLayout,
              // ),
              // SizedBox(height: fieldSpacing),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pinController,
                      focusNode: pinFieldFocusNode,
                      enabled: !isSubmitting,
                      obscureText: true,
                      style: isTvLayout ? theme.textTheme.titleMedium : null,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      onSubmitted: (_) => confirmPinFieldFocusNode.requestFocus(),
                      decoration: const InputDecoration(labelText: '4-digit PIN'),
                    ),
                  ),
                  SizedBox(width: fieldSpacing),
                  Expanded(
                    child: TextField(
                      controller: confirmPinController,
                      focusNode: confirmPinFieldFocusNode,
                      enabled: !isSubmitting,
                      obscureText: true,
                      style: isTvLayout ? theme.textTheme.titleMedium : null,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                      onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                      decoration: const InputDecoration(labelText: 'Confirm PIN'),
                    ),
                  ),
                ],
              ),
              // SizedBox(height: fieldSpacing),
              // Text(
              //   'This PIN unlocks the saved profile on future launches without re-entering your Immich email and password.',
              //   style: (isTvLayout ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)?.copyWith(color: AppColors.textMuted, height: 1.5),
              // ),
            ],
            // SizedBox(height: isTvLayout ? 20 : 24),
            // Row(
            //   children: [
            //     ShortcutHint(label: 'Enter', size: isTvLayout ? ShortcutHintSize.large : ShortcutHintSize.medium),
            //     const SizedBox(width: AppSpacing.sm),
            //     Expanded(
            //       child: Text(helperText, style: (isTvLayout ? theme.textTheme.bodyMedium : theme.textTheme.bodyMedium)?.copyWith(color: AppColors.textMuted)),
            //     ),
            //   ],
            // ),
            SizedBox(height: isTvLayout ? 16 : 18),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: FilledButton(
                focusNode: actionButtonFocusNode,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: isTvLayout ? 10 : 14),
                  textStyle: buttonTextStyle,
                ),
                onPressed: isSubmitting ? null : onPrimaryAction,
                child: Text(isSubmitting ? 'Working...' : primaryButtonLabel),
              ),
            ),
            // if (hasSavedProfiles || !isServerStep) ...[
            //   SizedBox(height: isTvLayout ? 12 : 12),
            //   SizedBox(
            //     width: double.infinity,
            //     height: buttonHeight,
            //     child: OutlinedButton(
            //       style: OutlinedButton.styleFrom(
            //         padding: EdgeInsets.symmetric(horizontal: 18, vertical: isTvLayout ? 10 : 14),
            //         textStyle: buttonTextStyle,
            //       ),
            //       onPressed: isSubmitting ? null : onSecondaryAction,
            //       child: Text(secondaryButtonLabel),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}
