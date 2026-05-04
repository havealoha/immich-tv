import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import 'profile_avatar_color.dart';

class PinUnlockDialog extends StatefulWidget {
  const PinUnlockDialog({super.key, required this.profile});

  final SavedProfile profile;

  @override
  State<PinUnlockDialog> createState() => _PinUnlockDialogState();
}

class _PinUnlockDialogState extends State<PinUnlockDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFieldFocusNode = FocusNode(debugLabel: 'pin.field');
  final FocusNode _cancelButtonFocusNode = FocusNode(debugLabel: 'pin.cancel');
  final FocusNode _unlockButtonFocusNode = FocusNode(debugLabel: 'pin.unlock');
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFieldFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _unlockButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
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
              TextField(
                controller: _pinController,
                focusNode: _pinFieldFocusNode,
                autofocus: true,
                enabled: !_isSubmitting,
                obscureText: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  } else {
                    setState(() {});
                  }
                },
                onSubmitted: !_isSubmitting ? (_) => _submit() : null,
                decoration: const InputDecoration(
                  labelText: '4-digit PIN',
                  hintText: 'Enter PIN',
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
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(
                      label: 'Cancel',
                      focusNode: _cancelButtonFocusNode,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DialogActionButton(
                      label: _isSubmitting ? 'Unlocking...' : 'Unlock',
                      focusNode: _unlockButtonFocusNode,
                      onPressed:
                          _isSubmitting ||
                              _pinController.text.trim().length != 4
                          ? null
                          : _submit,
                      isPrimary: true,
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

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
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
      setState(() {
        _isSubmitting = false;
        _pinController.clear();
        _errorMessage = error is AppException
            ? error.message
            : 'We could not unlock that profile right now.';
      });
      _pinFieldFocusNode.requestFocus();
    }
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.label,
    required this.focusNode,
    required this.onPressed,
    required this.isPrimary,
  });

  final String label;
  final FocusNode focusNode;
  final VoidCallback? onPressed;
  final bool isPrimary;

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
            color: isPrimary
                ? (onPressed == null
                      ? AppColors.surfaceMuted
                      : (isActive
                            ? const Color(0xFF3997FF)
                            : AppColors.immichBlue))
                : (isActive
                      ? const Color(0xFF17303E)
                      : const Color(0xFF10202A)),
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
