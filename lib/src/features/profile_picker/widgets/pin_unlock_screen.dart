import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_scale.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/on_screen_keyboard/on_screen_keyboard.dart';
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
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_handlePinTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pinFieldFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.removeListener(_handlePinTextChanged);
    _pinController.dispose();
    _pinFieldFocusNode.dispose();
    _pinKeyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    final fieldSpacing = scale.space(14, min: 10, max: 18);
    final profileColor = profileAvatarColor(widget.profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
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
                            (theme.textTheme.headlineSmall ??
                                    theme.textTheme.titleLarge)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      widget.profile.name,
                      textAlign: TextAlign.center,
                      style:
                          (theme.textTheme.headlineMedium ??
                                  theme.textTheme.headlineSmall)
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
                    SizedBox(height: fieldSpacing),
                    Focus(
                      onKeyEvent: (_, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _pinKeyboardFocusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
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
                            (theme.textTheme.titleMedium ??
                                    theme.textTheme.bodyLarge)
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
                    SizedBox(height: fieldSpacing),
                    OnScreenKeyboard(
                      controller: _pinController,
                      focusNode: _pinFieldFocusNode,
                      firstKeyFocusNode: _pinKeyboardFocusNode,
                      type: OnScreenKeyboardType.numeric,
                      enabled: !_isSubmitting,
                      allowDecimal: false,
                      showDecimalButton: false,
                      showDoneButton: false,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePinTextChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    if (_pinController.text.length == 4 && !_isSubmitting) {
      unawaited(_submit());
    }
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
