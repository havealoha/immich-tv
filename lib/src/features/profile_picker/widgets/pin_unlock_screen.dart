import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_scale.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/on_screen_keyboard/on_screen_keyboard.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import 'profile_avatar_color.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key, required this.profile});

  final SavedProfile profile;

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFieldFocusNode = FocusNode(debugLabel: 'pin.field');
  final FocusNode _pinKeyboardFocusNode = FocusNode(debugLabel: 'pin.keyboard');
  final FocusNode _unlockButtonFocusNode = FocusNode(debugLabel: 'pin.unlock');
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFieldFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFieldFocusNode.dispose();
    _pinKeyboardFocusNode.dispose();
    _unlockButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    final isSystemKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final otpSpacing = scale.space(12, min: 10, max: 16);
    final otpDigitSize = scale.sizeOf(68, min: 48, max: 72);
    final buttonWidth = (otpDigitSize * 4) + (otpSpacing * 3);
    final profileColor = profileAvatarColor(widget.profile);
    final pin = _pinController.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: buttonWidth + 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: profileColor,
                      foregroundColor: Colors.white,
                      child: Text(
                        widget.profile.initials,
                        style:
                            (theme.textTheme.headlineSmall
                                    ?? theme.textTheme.titleLarge)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.profile.name,
                      textAlign: TextAlign.center,
                      style:
                          (theme.textTheme.headlineMedium
                                  ?? theme.textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enter your 4-digit PIN',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: scale.text(15, min: 13, max: 17),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: otpSpacing * 1.6),
                    Shortcuts(
                      shortcuts: const <ShortcutActivator, Intent>{
                        SingleActivator(
                          LogicalKeyboardKey.arrowDown,
                        ): DirectionalFocusIntent(TraversalDirection.down),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          DirectionalFocusIntent:
                              CallbackAction<DirectionalFocusIntent>(
                                onInvoke: (intent) {
                                  if (intent.direction ==
                                      TraversalDirection.down) {
                                    _pinKeyboardFocusNode.requestFocus();
                                  }
                                  return null;
                                },
                              ),
                        },
                        child: TextField(
                          controller: _pinController,
                          focusNode: _pinFieldFocusNode,
                          enabled: !_isSubmitting,
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
                          style:
                              (theme.textTheme.titleMedium
                                      ?? theme.textTheme.bodyLarge)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: scale.text(22, min: 18, max: 26),
                                    letterSpacing: 6,
                                  ),
                          decoration: const InputDecoration(
                            labelText: 'PIN',
                            hintText: '0000',
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: otpSpacing * 1.2),
                    OnScreenKeyboard(
                      controller: _pinController,
                      focusNode: _pinFieldFocusNode,
                      firstKeyFocusNode: _pinKeyboardFocusNode,
                      type: OnScreenKeyboardType.numeric,
                      enabled: !_isSubmitting,
                      allowDecimal: false,
                      showDecimalButton: false,
                      maxLength: 4,
                      onMaxLengthReached: _isSubmitting ? null : _submit,
                      doneLabel: 'Unlock',
                      onChanged: (_) => _handleDigitChanged(),
                      onDone: _isSubmitting ? null : _submit,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: buttonWidth,
                      height: 56,
                      child: _ActionButton(
                        label: _isSubmitting ? 'Unlocking...' : 'Unlock',
                        focusNode: _unlockButtonFocusNode,
                        canRequestFocus: !isSystemKeyboardVisible,
                        onPressed: _isSubmitting || pin.length != 4
                            ? null
                            : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDigitChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final pin = _pinController.text;
    if (pin.length != 4 || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session = await context
          .read<AuthRepository>()
          .signInWithSavedProfile(profileId: widget.profile.id, pin: pin);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(session);
    } catch (error) {
      _pinController.clear();
      setState(() {
        _isSubmitting = false;
        _errorMessage = error is AppException
            ? error.message
            : 'We could not unlock that profile right now.';
      });
      _pinFieldFocusNode.requestFocus();
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.focusNode,
    required this.onPressed,
    this.canRequestFocus = true,
  });

  final String label;
  final FocusNode focusNode;
  final VoidCallback? onPressed;
  final bool canRequestFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExcludeFocus(
      excluding: !canRequestFocus,
      child: TvFocusable(
        focusNode: focusNode,
        onPressed: onPressed,
        enabled: onPressed != null,
        builder: (context, focusState) {
          final isActive = focusState.isActive;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 56,
            decoration: BoxDecoration(
              color: onPressed == null
                  ? AppColors.surfaceMuted
                  : (isActive ? const Color(0xFF3997FF) : AppColors.immichBlue),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: focusState.isFocused ? AppColors.focus : AppColors.border,
                width: focusState.isFocused ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onPressed == null
                      ? AppColors.textMuted
                      : AppColors.actionForeground,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
