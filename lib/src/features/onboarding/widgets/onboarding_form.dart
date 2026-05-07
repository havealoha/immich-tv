import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_scale.dart';
import '../cubit/onboarding_state.dart';
import 'onboarding_status_banner.dart';

class OnboardingForm extends StatelessWidget {
  const OnboardingForm({
    super.key,
    required this.theme,
    required this.state,
    required this.isTvLayout,
    required this.useMockServices,
    required this.serverController,
    required this.emailController,
    required this.passwordController,
    required this.pinController,
    required this.confirmPinController,
    required this.pinDigitControllers,
    required this.confirmPinDigitControllers,
    required this.pinDigitFocusNodes,
    required this.confirmPinDigitFocusNodes,
    required this.serverFieldFocusNode,
    required this.emailFieldFocusNode,
    required this.passwordFieldFocusNode,
    required this.pinFieldFocusNode,
    required this.confirmPinFieldFocusNode,
    required this.actionButtonFocusNode,
    required this.isConfirmingPin,
    required this.onPrimaryAction,
  });

  final ThemeData theme;
  final OnboardingState state;
  final bool isTvLayout;
  final bool useMockServices;
  final TextEditingController serverController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController pinController;
  final TextEditingController confirmPinController;
  final List<TextEditingController> pinDigitControllers;
  final List<TextEditingController> confirmPinDigitControllers;
  final List<FocusNode> pinDigitFocusNodes;
  final List<FocusNode> confirmPinDigitFocusNodes;
  final FocusNode serverFieldFocusNode;
  final FocusNode emailFieldFocusNode;
  final FocusNode passwordFieldFocusNode;
  final FocusNode pinFieldFocusNode;
  final FocusNode confirmPinFieldFocusNode;
  final FocusNode actionButtonFocusNode;
  final bool isConfirmingPin;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    final typographyScale = scale.typographyScale;
    final isCompactWidth = scale.isCompactWidth;
    final isSubmitting = state.isBusy;
    final isServerStep = state.step == OnboardingStep.server;
    final isCredentialsStep = state.step == OnboardingStep.credentials;

    final primaryButtonLabel = switch (state.step) {
      OnboardingStep.server => 'Validate server',
      OnboardingStep.credentials => 'Continue to PIN setup',
      OnboardingStep.pin =>
        isConfirmingPin
            ? 'Save profile and continue'
            : 'Continue to confirm PIN',
    };

    final fieldTextStyle =
        (isTvLayout ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
            ?.copyWith(fontSize: scale.text(18, min: 15, max: 22));
    final pinPromptStyle =
        (isTvLayout ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
            ?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: scale.text(22, min: 18, max: 26),
            );
    final pinCaptionStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      fontSize: scale.text(15, min: 13, max: 17),
      height: 1.45,
    );
    final fieldSpacing = scale.space(18, min: 14, max: 22);
    final buttonHeight = scale.sizeOf(56, min: 50, max: 60);
    final statusPadding = scale.space(16, min: 14, max: 20);
    final otpSpacing = scale.space(12, min: 10, max: 16);
    final otpDigitSize = scale.sizeOf(
      isCompactWidth ? 58 : 68,
      min: 48,
      max: 72,
    );
    final fieldWidthFactor = isTvLayout
        ? 0.92
        : isCompactWidth
        ? 1.0
        : 0.94;
    final buttonTextStyle =
        (isTvLayout ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
            ?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.1,
              fontSize: scale.text(18, min: 15, max: 20),
            );

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          contentPadding: EdgeInsets.symmetric(
            horizontal: scale.space(18, min: 16, max: 22),
            vertical: scale.space(16, min: 14, max: 18),
          ),
          labelStyle:
              (isTvLayout
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyLarge)
                  ?.copyWith(fontSize: scale.text(16, min: 14, max: 18)),
          hintStyle:
              (isTvLayout
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyLarge)
                  ?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: scale.text(16, min: 14, max: 18),
                  ),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
          fontSize: scale.text(16, min: 14, max: 18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (useMockServices) ...[
              OnboardingStatusBanner(
                icon: Icons.auto_awesome_outlined,
                color: const Color(0xFF6FE0DB),
                message:
                    'Demo mode is on. Authentication, library browsing, pagination, and fullscreen viewing are currently backed by mock data so we can polish the UI before real API rollout.',
                padding: statusPadding,
                isTvLayout: isTvLayout,
                typographyScale: typographyScale,
              ),
              SizedBox(height: fieldSpacing),
            ],
            if (state.errorMessage case final message?) ...[
              OnboardingStatusBanner(
                icon: Icons.error_outline,
                color: const Color(0xFFFF907C),
                message: message,
                padding: statusPadding,
                isTvLayout: isTvLayout,
                typographyScale: typographyScale,
              ),
              SizedBox(height: fieldSpacing),
            ],
            if (isServerStep) ...[
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: TextField(
                  controller: serverController,
                  focusNode: serverFieldFocusNode,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  style: fieldTextStyle,
                  onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                  decoration: const InputDecoration(
                    labelText: 'Immich server URL',
                    hintText: 'https://photos.example.com',
                  ),
                ),
              ),
            ] else if (isCredentialsStep) ...[
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: TextField(
                  controller: emailController,
                  focusNode: emailFieldFocusNode,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.next,
                  style: fieldTextStyle,
                  onSubmitted: (_) => passwordFieldFocusNode.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
              SizedBox(height: fieldSpacing),
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: TextField(
                  controller: passwordController,
                  focusNode: passwordFieldFocusNode,
                  enabled: !isSubmitting,
                  obscureText: true,
                  style: fieldTextStyle,
                  textInputAction: TextInputAction.next,
                  onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ),
            ] else ...[
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: _PinOtpStep(
                  title: isConfirmingPin
                      ? 'Confirm your 4-digit PIN'
                      : 'Create a 4-digit PIN',
                  caption: isConfirmingPin
                      ? 'Enter the same four digits again.'
                      : 'Use the PIN you want to unlock this profile on TV.',
                  titleStyle: pinPromptStyle,
                  captionStyle: pinCaptionStyle,
                  digitSize: otpDigitSize,
                  spacing: otpSpacing,
                  enabled: !isSubmitting,
                  controllers: isConfirmingPin
                      ? confirmPinDigitControllers
                      : pinDigitControllers,
                  focusNodes: isConfirmingPin
                      ? confirmPinDigitFocusNodes
                      : pinDigitFocusNodes,
                  fieldTextStyle: fieldTextStyle,
                  onComplete: !isSubmitting ? onPrimaryAction : null,
                ),
              ),
            ],
            SizedBox(height: scale.space(18, min: 16, max: 22)),
            _ScaledFieldWidth(
              widthFactor: fieldWidthFactor,
              child: SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: FilledButton(
                  focusNode: actionButtonFocusNode,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.space(20, min: 18, max: 24),
                      vertical: scale.space(12, min: 10, max: 14),
                    ),
                    textStyle: buttonTextStyle,
                  ),
                  onPressed: isSubmitting ? null : onPrimaryAction,
                  child: Text(isSubmitting ? 'Working...' : primaryButtonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinOtpStep extends StatelessWidget {
  const _PinOtpStep({
    required this.title,
    required this.caption,
    required this.titleStyle,
    required this.captionStyle,
    required this.digitSize,
    required this.spacing,
    required this.enabled,
    required this.controllers,
    required this.focusNodes,
    required this.fieldTextStyle,
    this.onComplete,
  });

  final String title;
  final String caption;
  final TextStyle? titleStyle;
  final TextStyle? captionStyle;
  final double digitSize;
  final double spacing;
  final bool enabled;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final TextStyle? fieldTextStyle;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: titleStyle, textAlign: TextAlign.center),
        SizedBox(height: spacing),
        Text(caption, style: captionStyle, textAlign: TextAlign.center),
        SizedBox(height: spacing * 1.4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(controllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == controllers.length - 1 ? 0 : spacing,
              ),
              child: _OtpDigitField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                previousFocusNode: index > 0 ? focusNodes[index - 1] : null,
                nextFocusNode: index < focusNodes.length - 1
                    ? focusNodes[index + 1]
                    : null,
                enabled: enabled,
                size: digitSize.clamp(48.0, 72.0),
                textStyle: fieldTextStyle,
                onComplete: index == controllers.length - 1 ? onComplete : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.size,
    this.previousFocusNode,
    this.nextFocusNode,
    this.textStyle,
    this.onComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool enabled;
  final double size;
  final TextStyle? textStyle;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        autofocus: false,
        textAlign: TextAlign.center,
        style: textStyle?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: (textStyle?.fontSize ?? 18) + 2,
          letterSpacing: 1,
        ),
        obscureText: true,
        keyboardType: TextInputType.number,
        textInputAction: nextFocusNode == null
            ? TextInputAction.done
            : TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          hintText: '0',
          counterText: '',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 0,
            vertical: (size * 0.38).clamp(18.0, 28.0),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (nextFocusNode != null) {
              nextFocusNode!.requestFocus();
            } else {
              focusNode.unfocus();
              onComplete?.call();
            }
            return;
          }

          if (previousFocusNode != null) {
            previousFocusNode!.requestFocus();
          }
        },
      ),
    );
  }
}

class _ScaledFieldWidth extends StatelessWidget {
  const _ScaledFieldWidth({required this.widthFactor, required this.child});

  final double widthFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(widthFactor: widthFactor, child: child),
    );
  }
}
