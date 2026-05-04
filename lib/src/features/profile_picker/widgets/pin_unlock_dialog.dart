import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_spacing.dart';
import 'pin_pad_button.dart';
import 'profile_avatar_color.dart';

class PinUnlockDialog extends StatefulWidget {
  const PinUnlockDialog({super.key, required this.profile});

  final SavedProfile profile;

  @override
  State<PinUnlockDialog> createState() => _PinUnlockDialogState();
}

class _PinUnlockDialogState extends State<PinUnlockDialog> {
  static const _digitLayout = <String>[
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'clear',
    '0',
    'back',
  ];

  final FocusNode _dialogFocusNode = FocusNode(debugLabel: 'pinDialog');
  String _pin = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _dialogFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Focus(
        autofocus: true,
        focusNode: _dialogFocusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }

          final keyLabel = event.logicalKey.keyLabel;
          if (RegExp(r'^\d$').hasMatch(keyLabel)) {
            _addDigit(keyLabel);
            return KeyEventResult.handled;
          }

          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _removeDigit();
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: const Color(0xFF09141B),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 32,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: profileAvatarColor(widget.profile),
                    foregroundColor: Colors.white,
                    child: Text(
                      widget.profile.initials,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your 4-digit PIN to continue.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 72,
                      margin: EdgeInsets.only(
                        right: index == 3 ? 0 : AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11202A),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: index < _pin.length
                              ? AppColors.focus
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          index < _pin.length ? '•' : '',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.8,
                ),
                itemCount: _digitLayout.length,
                itemBuilder: (context, index) {
                  final value = _digitLayout[index];
                  return PinPadButton(
                    label: _labelForKey(value),
                    autofocus: index == 0,
                    onPressed: _isSubmitting ? null : () => _handleKey(value),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting || _pin.length != 4
                          ? null
                          : _submit,
                      child: Text(_isSubmitting ? 'Unlocking...' : 'Unlock'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleKey(String value) {
    switch (value) {
      case 'clear':
        setState(() {
          _pin = '';
          _errorMessage = null;
        });
        return;
      case 'back':
        _removeDigit();
        return;
      default:
        _addDigit(value);
    }
  }

  void _addDigit(String digit) {
    if (_pin.length >= 4 || _isSubmitting) {
      return;
    }

    setState(() {
      _pin += digit;
      _errorMessage = null;
    });
  }

  void _removeDigit() {
    if (_pin.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (_pin.length != 4 || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session = await context
          .read<AuthRepository>()
          .signInWithSavedProfile(profileId: widget.profile.id, pin: _pin);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(session);
    } catch (error) {
      setState(() {
        _isSubmitting = false;
        _pin = '';
        _errorMessage = error is AppException
            ? error.message
            : 'We could not unlock that profile right now.';
      });
    }
  }

  String _labelForKey(String value) {
    return switch (value) {
      'clear' => 'Clear',
      'back' => 'Back',
      _ => value,
    };
  }
}
