import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../shared/presentation/app_breakpoints.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import 'profile_avatar_color.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key, required this.profile});

  final SavedProfile profile;

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _digitFocusNodes;
  final FocusNode _unlockButtonFocusNode = FocusNode(debugLabel: 'pin.unlock');
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(4, (_) => TextEditingController());
    _digitFocusNodes = List.generate(
      4,
      (index) => FocusNode(debugLabel: 'pin.field.$index'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _digitFocusNodes.first.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final focusNode in _digitFocusNodes) {
      focusNode.dispose();
    }
    _unlockButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final isTvLayout = viewport.width >= AppBreakpoints.tv;
    final widthScale = (viewport.width / 1440).clamp(0.72, 1.28);
    final typographyScale = ((widthScale * 0.7) + 0.3).clamp(0.82, 1.22);
    final otpSpacing = (12.0 * widthScale).clamp(10.0, 18.0);
    final otpDigitSize = ((isTvLayout ? 68.0 : 58.0) * typographyScale).clamp(
      48.0,
      82.0,
    );
    final buttonWidth = (otpDigitSize * 4) + (otpSpacing * 3);
    final profileColor = profileAvatarColor(widget.profile);
    final pin = _currentPin;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1B4A5A), Color(0xFF10232E), Color(0xFF08131A)],
            center: Alignment(-0.25, -0.8),
            radius: 1.3,
          ),
        ),
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
                      radius: isTvLayout ? 40 : 34,
                      backgroundColor: profileColor,
                      foregroundColor: Colors.white,
                      child: Text(
                        widget.profile.initials,
                        style:
                            (isTvLayout
                                    ? theme.textTheme.headlineSmall
                                    : theme.textTheme.titleLarge)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.profile.name,
                      textAlign: TextAlign.center,
                      style:
                          (isTvLayout
                                  ? theme.textTheme.headlineMedium
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Enter your 4-digit PIN',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: (15.0 * typographyScale).clamp(13.0, 20.0),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: otpSpacing * 1.6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_digitControllers.length, (
                        index,
                      ) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == _digitControllers.length - 1
                                ? 0
                                : otpSpacing,
                          ),
                          child: _OtpDigitField(
                            controller: _digitControllers[index],
                            focusNode: _digitFocusNodes[index],
                            previousFocusNode: index > 0
                                ? _digitFocusNodes[index - 1]
                                : null,
                            nextFocusNode: index < _digitFocusNodes.length - 1
                                ? _digitFocusNodes[index + 1]
                                : null,
                            enabled: !_isSubmitting,
                            size: otpDigitSize,
                            textStyle:
                                (isTvLayout
                                        ? theme.textTheme.titleMedium
                                        : theme.textTheme.bodyLarge)
                                    ?.copyWith(
                                      fontSize: (18.0 * typographyScale).clamp(
                                        15.0,
                                        24.0,
                                      ),
                                    ),
                            onChanged: _handleDigitChanged,
                            onComplete: !_isSubmitting ? _submit : null,
                          ),
                        );
                      }),
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

  String get _currentPin =>
      _digitControllers.map((controller) => controller.text).join();

  void _handleDigitChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final pin = _currentPin;
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
      for (final controller in _digitControllers) {
        controller.clear();
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage = error is AppException
            ? error.message
            : 'We could not unlock that profile right now.';
      });
      _digitFocusNodes.first.requestFocus();
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.focusNode,
    required this.onPressed,
  });

  final String label;
  final FocusNode focusNode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvFocusable(
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
    );
  }
}

class _OtpDigitField extends StatelessWidget {
  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.size,
    required this.onChanged,
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
  final VoidCallback onChanged;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
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
          onChanged();
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
