import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';

enum RemoteInputMethod { tvKeyboard, phoneQr }

class RemoteInputMethodSwitch extends StatelessWidget {
  const RemoteInputMethodSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.firstFocusNode,
    this.onMoveDown,
  });

  final RemoteInputMethod value;
  final ValueChanged<RemoteInputMethod> onChanged;
  final bool enabled;
  final FocusNode? firstFocusNode;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          onMoveDown?.call();
          return onMoveDown == null
              ? KeyEventResult.ignored
              : KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typing method',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              _MethodButton(
                icon: Icons.keyboard_rounded,
                title: 'TV keyboard',
                subtitle: 'Use remote',
                selected: value == RemoteInputMethod.tvKeyboard,
                enabled: enabled,
                focusNode: firstFocusNode,
                onPressed: () => onChanged(RemoteInputMethod.tvKeyboard),
              ),
              const SizedBox(width: AppSpacing.sm),
              _MethodButton(
                icon: Icons.qr_code_2_rounded,
                title: 'Scan QR',
                subtitle: 'Type on phone',
                selected: value == RemoteInputMethod.phoneQr,
                enabled: enabled,
                onPressed: () => onChanged(RemoteInputMethod.phoneQr),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.focusNode,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final foreground = !enabled
        ? AppColors.textMuted
        : selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return TvFocusable(
      focusNode: focusNode,
      enabled: enabled,
      onPressed: onPressed,
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: isFocused ? AppColors.focus : Colors.transparent,
              width: isFocused ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isFocused
                ? const [
                    BoxShadow(
                      color: AppColors.focusGlow,
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppColors.focus : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: foreground),
                  const SizedBox(width: AppSpacing.xxs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.78),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
