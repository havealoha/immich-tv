import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_scale.dart';
import '../../../shared/presentation/widgets/on_screen_keyboard/on_screen_keyboard.dart';
import '../cubit/onboarding_state.dart';
import 'onboarding_status_banner.dart';

enum OnboardingKeyboardField { server, email, password, pin, confirmPin }

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
    required this.serverKeyboardFocusNode,
    required this.emailKeyboardFocusNode,
    required this.passwordKeyboardFocusNode,
    required this.pinKeyboardFocusNode,
    required this.confirmPinKeyboardFocusNode,
    required this.isConfirmingPin,
    required this.activeKeyboardField,
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
  final FocusNode serverKeyboardFocusNode;
  final FocusNode emailKeyboardFocusNode;
  final FocusNode passwordKeyboardFocusNode;
  final FocusNode pinKeyboardFocusNode;
  final FocusNode confirmPinKeyboardFocusNode;
  final bool isConfirmingPin;
  final OnboardingKeyboardField? activeKeyboardField;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    final typographyScale = scale.typographyScale;
    final isCompactWidth = scale.isCompactWidth;
    const isTvKeyboardEntry = true;
    final isSystemKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isSubmitting = state.isBusy;
    final isServerStep = state.step == OnboardingStep.server;
    final isCredentialsStep = state.step == OnboardingStep.credentials;

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
    final statusPadding = scale.space(16, min: 14, max: 20);
    final fieldWidthFactor = isTvLayout
        ? 0.92
        : isCompactWidth
        ? 1.0
        : 0.94;
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
                child: _OnboardingTextField(
                  controller: serverController,
                  focusNode: serverFieldFocusNode,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  style: fieldTextStyle,
                  readOnly: isTvKeyboardEntry,
                  keyboardFocusNode: serverKeyboardFocusNode,
                  lockDirectionalFocusToKeyboard: isSystemKeyboardVisible,
                  onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                  decoration: const InputDecoration(
                    labelText: 'Immich server URL',
                    hintText: 'https://photos.example.com',
                  ),
                ),
              ),
              if (isTvKeyboardEntry &&
                  activeKeyboardField == OnboardingKeyboardField.server) ...[
                SizedBox(height: fieldSpacing),
                _ScaledFieldWidth(
                  widthFactor: fieldWidthFactor,
                  child: OnScreenKeyboard(
                    controller: serverController,
                    focusNode: serverFieldFocusNode,
                    firstKeyFocusNode: serverKeyboardFocusNode,
                    enabled: !isSubmitting,
                    doneLabel: 'Next',
                    onDone: onPrimaryAction,
                  ),
                ),
              ],
            ] else if (isCredentialsStep) ...[
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: _OnboardingTextField(
                  controller: emailController,
                  focusNode: emailFieldFocusNode,
                  nextFocusNode: passwordFieldFocusNode,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.next,
                  style: fieldTextStyle,
                  readOnly: isTvKeyboardEntry,
                  keyboardFocusNode: emailKeyboardFocusNode,
                  lockDirectionalFocusToKeyboard: isSystemKeyboardVisible,
                  onSubmitted: (_) => passwordFieldFocusNode.requestFocus(),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
              if (isTvKeyboardEntry &&
                  activeKeyboardField == OnboardingKeyboardField.email) ...[
                SizedBox(height: fieldSpacing),
                _ScaledFieldWidth(
                  widthFactor: fieldWidthFactor,
                  child: OnScreenKeyboard(
                    controller: emailController,
                    focusNode: emailFieldFocusNode,
                    firstKeyFocusNode: emailKeyboardFocusNode,
                    enabled: !isSubmitting,
                    doneLabel: 'Next',
                    onDone: () => passwordFieldFocusNode.requestFocus(),
                  ),
                ),
              ],
              SizedBox(height: fieldSpacing),
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: _OnboardingTextField(
                  controller: passwordController,
                  focusNode: passwordFieldFocusNode,
                  previousFocusNode: emailFieldFocusNode,
                  enabled: !isSubmitting,
                  obscureText: true,
                  style: fieldTextStyle,
                  textInputAction: TextInputAction.next,
                  readOnly: isTvKeyboardEntry,
                  keyboardFocusNode: passwordKeyboardFocusNode,
                  lockDirectionalFocusToKeyboard: isSystemKeyboardVisible,
                  onSubmitted: !isSubmitting ? (_) => onPrimaryAction() : null,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ),
              if (isTvKeyboardEntry &&
                  activeKeyboardField == OnboardingKeyboardField.password) ...[
                SizedBox(height: fieldSpacing),
                _ScaledFieldWidth(
                  widthFactor: fieldWidthFactor,
                  child: OnScreenKeyboard(
                    controller: passwordController,
                    focusNode: passwordFieldFocusNode,
                    firstKeyFocusNode: passwordKeyboardFocusNode,
                    enabled: !isSubmitting,
                    doneLabel: 'Continue',
                    onDone: onPrimaryAction,
                  ),
                ),
              ],
            ] else ...[
              _ScaledFieldWidth(
                widthFactor: fieldWidthFactor,
                child: _TvPinStep(
                  title: isConfirmingPin
                      ? 'Confirm your 4-digit PIN'
                      : 'Create a 4-digit PIN',
                  caption: isConfirmingPin
                      ? 'Enter the same four digits again.'
                      : 'Use the PIN you want to unlock this profile on TV.',
                  titleStyle: pinPromptStyle,
                  captionStyle: pinCaptionStyle,
                  controller: isConfirmingPin
                      ? confirmPinController
                      : pinController,
                  focusNode: isConfirmingPin
                      ? confirmPinFieldFocusNode
                      : pinFieldFocusNode,
                  keyboardFocusNode: isConfirmingPin
                      ? confirmPinKeyboardFocusNode
                      : pinKeyboardFocusNode,
                  fieldTextStyle: fieldTextStyle,
                  enabled: !isSubmitting,
                ),
              ),
              if (isTvKeyboardEntry &&
                  activeKeyboardField ==
                      (isConfirmingPin
                          ? OnboardingKeyboardField.confirmPin
                          : OnboardingKeyboardField.pin)) ...[
                SizedBox(height: fieldSpacing),
                _ScaledFieldWidth(
                  widthFactor: fieldWidthFactor,
                  child: OnScreenKeyboard(
                    controller: isConfirmingPin
                        ? confirmPinController
                        : pinController,
                    focusNode: isConfirmingPin
                        ? confirmPinFieldFocusNode
                        : pinFieldFocusNode,
                    firstKeyFocusNode: isConfirmingPin
                        ? confirmPinKeyboardFocusNode
                        : pinKeyboardFocusNode,
                    type: OnScreenKeyboardType.numeric,
                    enabled: !isSubmitting,
                    allowDecimal: false,
                    showDecimalButton: false,
                    showDoneButton: false,
                    maxLength: 4,
                    onMaxLengthReached: !isSubmitting ? onPrimaryAction : null,
                    doneLabel: isConfirmingPin ? 'Save' : 'Next',
                    onDone: onPrimaryAction,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingTextField extends StatelessWidget {
  const _OnboardingTextField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.textInputAction,
    required this.decoration,
    this.previousFocusNode,
    this.nextFocusNode,
    this.style,
    this.onSubmitted,
    this.lockDirectionalFocusToKeyboard = false,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardFocusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final bool enabled;
  final TextInputAction textInputAction;
  final InputDecoration decoration;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;
  final bool lockDirectionalFocusToKeyboard;
  final bool obscureText;
  final bool readOnly;
  final FocusNode? keyboardFocusNode;

  @override
  Widget build(BuildContext context) {
    if (readOnly && keyboardFocusNode != null) {
      return Focus(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          final targetFocusNode = switch (event.logicalKey) {
            LogicalKeyboardKey.arrowUp => previousFocusNode,
            LogicalKeyboardKey.arrowDown => keyboardFocusNode,
            _ => null,
          };
          if (targetFocusNode == null) {
            return KeyEventResult.ignored;
          }
          targetFocusNode.requestFocus();
          return KeyEventResult.handled;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: true,
          showCursor: true,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: style,
          onSubmitted: onSubmitted,
          decoration: decoration,
        ),
      );
    }

    if (lockDirectionalFocusToKeyboard || readOnly) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        showCursor: true,
        obscureText: obscureText,
        textInputAction: textInputAction,
        style: style,
        onSubmitted: onSubmitted,
        decoration: decoration,
      );
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveFocusIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveFocusIntent(1),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MoveFocusIntent: CallbackAction<_MoveFocusIntent>(
            onInvoke: (intent) {
              final targetFocusNode = switch (intent.delta) {
                -1 => previousFocusNode,
                1 => nextFocusNode,
                _ => null,
              };
              targetFocusNode?.requestFocus();
              return null;
            },
          ),
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          showCursor: true,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: style,
          onSubmitted: onSubmitted,
          decoration: decoration,
        ),
      ),
    );
  }
}

class _TvPinStep extends StatelessWidget {
  const _TvPinStep({
    required this.title,
    required this.caption,
    required this.titleStyle,
    required this.captionStyle,
    required this.controller,
    required this.focusNode,
    required this.keyboardFocusNode,
    required this.fieldTextStyle,
    required this.enabled,
  });

  final String title;
  final String caption;
  final TextStyle? titleStyle;
  final TextStyle? captionStyle;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode keyboardFocusNode;
  final TextStyle? fieldTextStyle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: titleStyle, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(caption, style: captionStyle, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              keyboardFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            readOnly: true,
            showCursor: true,
            textAlign: TextAlign.center,
            obscureText: true,
            obscuringCharacter: '*',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: fieldTextStyle?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
            decoration: const InputDecoration(
              labelText: 'PIN',
              hintText: '0000',
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveFocusIntent extends Intent {
  const _MoveFocusIntent(this.delta);

  final int delta;
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
