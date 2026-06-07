import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_colors.dart';
import '../tv_focusable.dart';

/// A self-contained on-screen keyboard that can be copied into another project
/// without any app-specific dependencies.
///
/// To keep the native keyboard hidden, use it with a `readOnly: true` text
/// field and pass the same [TextEditingController] and optional [FocusNode].
class OnScreenKeyboard extends StatefulWidget {
  const OnScreenKeyboard({
    super.key,
    required this.controller,
    this.focusNode,
    this.firstKeyFocusNode,
    this.type = OnScreenKeyboardType.alphabetic,
    this.onChanged,
    this.onDone,
    this.onKeyPressed,
    this.showDoneButton = true,
    this.doneLabel = 'Done',
    this.allowDecimal = true,
    this.showDecimalButton = true,
    this.allowNegative = false,
    this.maxLength,
    this.onMaxLengthReached,
    this.enabled = true,
    this.keepSystemKeyboardHidden = true,
    this.includeSafeAreaBottomPadding = true,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 10),
    this.keySpacing = 6,
    this.keyBorderRadius = 10,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? firstKeyFocusNode;
  final OnScreenKeyboardType type;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDone;
  final ValueChanged<String>? onKeyPressed;
  final bool showDoneButton;
  final String doneLabel;
  final bool allowDecimal;
  final bool showDecimalButton;
  final bool allowNegative;
  final int? maxLength;
  final VoidCallback? onMaxLengthReached;
  final bool enabled;
  final bool keepSystemKeyboardHidden;
  final bool includeSafeAreaBottomPadding;
  final EdgeInsets padding;
  final double keySpacing;
  final double keyBorderRadius;

  @override
  State<OnScreenKeyboard> createState() => _OnScreenKeyboardState();
}

enum OnScreenKeyboardType { alphabetic, numeric }

enum _AlphabeticCase { lower, shifted, capsLock }

enum _SymbolPage { first, second }

class _OnScreenKeyboardState extends State<OnScreenKeyboard> {
  _AlphabeticCase _alphabeticCase = _AlphabeticCase.lower;
  bool _showSymbols = false;
  _SymbolPage _symbolPage = _SymbolPage.first;
  DateTime? _lastShiftTapAt;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _hideSystemKeyboardIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OnScreenKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    _hideSystemKeyboardIfNeeded();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    widget.onChanged?.call(widget.controller.text);
  }

  void _hideSystemKeyboardIfNeeded() {
    if (!widget.keepSystemKeyboardHidden) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    });
  }

  void _ensureTextFocus() {
    _hideSystemKeyboardIfNeeded();
  }

  void _insertText(String text) {
    if (!widget.enabled) return;

    _ensureTextFocus();
    final value = widget.controller.value;
    final currentText = value.text;
    final maxLength = widget.maxLength;
    final selection = value.selection;

    final int start;
    final int end;

    if (selection.isValid) {
      start = math.min(selection.start, selection.end);
      end = math.max(selection.start, selection.end);
    } else {
      start = currentText.length;
      end = currentText.length;
    }

    var newText = currentText.replaceRange(start, end, text);
    var newOffset = start + text.length;
    var reachedMaxLength = false;

    if (maxLength != null && newText.length > maxLength) {
      newText = newText.substring(0, maxLength);
      newOffset = math.min(newOffset, maxLength);
    }

    if (maxLength != null &&
        currentText.length < maxLength &&
        newText.length == maxLength) {
      reachedMaxLength = true;
    }

    widget.controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );

    widget.onKeyPressed?.call(text);

    if (reachedMaxLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onMaxLengthReached?.call();
        }
      });
    }

    if (widget.type == OnScreenKeyboardType.alphabetic && _alphabeticCase == _AlphabeticCase.shifted && RegExp(r'^[A-Za-z]$').hasMatch(text)) {
      setState(() {
        _alphabeticCase = _AlphabeticCase.lower;
      });
    }
  }

  void _backspace() {
    if (!widget.enabled) return;

    _ensureTextFocus();
    final value = widget.controller.value;
    final currentText = value.text;
    final selection = value.selection;

    if (currentText.isEmpty) return;

    late final int start;
    late final int end;

    if (selection.isValid && !selection.isCollapsed) {
      start = math.min(selection.start, selection.end);
      end = math.max(selection.start, selection.end);
    } else if (selection.isValid && selection.start > 0) {
      start = selection.start - 1;
      end = selection.start;
    } else if (!selection.isValid) {
      start = currentText.length - 1;
      end = currentText.length;
    } else {
      return;
    }

    final newText = currentText.replaceRange(start, end, '');

    widget.controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start),
      composing: TextRange.empty,
    );

    widget.onKeyPressed?.call('backspace');
  }

  void _handleShiftPressed() {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final bool doubleTap = _lastShiftTapAt != null && now.difference(_lastShiftTapAt!) <= const Duration(milliseconds: 320);

    setState(() {
      if (doubleTap && _alphabeticCase == _AlphabeticCase.shifted) {
        _alphabeticCase = _AlphabeticCase.capsLock;
      } else {
        switch (_alphabeticCase) {
          case _AlphabeticCase.lower:
            _alphabeticCase = _AlphabeticCase.shifted;
            break;
          case _AlphabeticCase.shifted:
          case _AlphabeticCase.capsLock:
            _alphabeticCase = _AlphabeticCase.lower;
            break;
        }
      }
    });

    _lastShiftTapAt = now;
  }

  void _toggleSymbolMode() {
    if (!widget.enabled) return;
    setState(() {
      _showSymbols = !_showSymbols;
      _symbolPage = _SymbolPage.first;
    });
  }

  void _toggleSymbolPage() {
    if (!widget.enabled) return;
    setState(() {
      _symbolPage = _symbolPage == _SymbolPage.first ? _SymbolPage.second : _SymbolPage.first;
    });
  }

  void _handleDone() {
    if (!widget.enabled) return;
    _ensureTextFocus();
    widget.onKeyPressed?.call('done');
    widget.onDone?.call();
  }

  String _displayLetter(String value) {
    switch (_alphabeticCase) {
      case _AlphabeticCase.lower:
        return value.toLowerCase();
      case _AlphabeticCase.shifted:
      case _AlphabeticCase.capsLock:
        return value.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _resolvePalette(theme);
    final mediaQuery = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = mediaQuery.size.shortestSide;
        final isTablet = shortestSide >= 600 || constraints.maxWidth >= 700;
        final spacing = widget.keySpacing;
        final keyHeight = isTablet ? 60.0 : 42.0;
        final iconSize = isTablet ? 22.0 : 20.0;
        final resolvedPadding = widget.includeSafeAreaBottomPadding
            ? widget.padding.add(EdgeInsets.only(bottom: math.max(mediaQuery.padding.bottom, isTablet ? 6 : 10)))
            : widget.padding;
        final keyLabelStyle = theme.textTheme.titleMedium?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w500,
          fontSize: isTablet ? 19 : 17,
          letterSpacing: -0.1,
        );
        final specialLabelStyle = theme.textTheme.bodyMedium?.copyWith(color: palette.mutedText, fontWeight: FontWeight.w600, fontSize: isTablet ? 14 : 13);

        return Container(
          color: palette.background,
          padding: resolvedPadding,
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildRows(
                keyHeight: keyHeight,
                spacing: spacing,
                iconSize: iconSize,
                palette: palette,
                keyLabelStyle: keyLabelStyle,
                specialLabelStyle: specialLabelStyle,
              ),
            ),
          ),
        );
      },
    );
  }

  _ResolvedKeyboardPalette _resolvePalette(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return _ResolvedKeyboardPalette(
      background: AppColors.background,
      key: AppColors.surface,
      specialKey: AppColors.surfaceMuted,
      activeKey: primary,
      text: AppColors.textPrimary,
      mutedText: AppColors.textSecondary,
      activeText: onPrimary,
    );
  }

  List<Widget> _buildRows({
    required double keyHeight,
    required double spacing,
    required double iconSize,
    required _ResolvedKeyboardPalette palette,
    required TextStyle? keyLabelStyle,
    required TextStyle? specialLabelStyle,
  }) {
    switch (widget.type) {
      case OnScreenKeyboardType.numeric:
        return _buildNumericRows(
          keyHeight: keyHeight,
          spacing: spacing,
          iconSize: iconSize,
          palette: palette,
          keyLabelStyle: keyLabelStyle,
          specialLabelStyle: specialLabelStyle,
        );
      case OnScreenKeyboardType.alphabetic:
        return _buildAlphabeticRows(
          keyHeight: keyHeight,
          spacing: spacing,
          iconSize: iconSize,
          palette: palette,
          keyLabelStyle: keyLabelStyle,
          specialLabelStyle: specialLabelStyle,
        );
    }
  }

  List<Widget> _buildAlphabeticRows({
    required double keyHeight,
    required double spacing,
    required double iconSize,
    required _ResolvedKeyboardPalette palette,
    required TextStyle? keyLabelStyle,
    required TextStyle? specialLabelStyle,
  }) {
    final rows = _showSymbols
        ? (_symbolPage == _SymbolPage.first
              ? <List<String>>[
                  <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
                  <String>['@', '#', '\$', '&', '*', '(', ')', '\'', '"'],
                  <String>['-', '+', '/', ':', ';', '!', '?'],
                ]
              : <List<String>>[
                  <String>['[', ']', '{', '}', '%', '^', '=', '_', '\\', '|'],
                  <String>['~', '<', '>', '€', '£', '¥', '•', '.', ','],
                  <String>['`', '…', '§', '°', '÷', '×'],
                ])
        : <List<String>>[
            <String>['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
            <String>['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
            <String>['z', 'x', 'c', 'v', 'b', 'n', 'm'],
          ];

    return [
      _buildKeyRow(
        keys: rows[0]
            .map((key) => _KeyboardKeySpec.character(label: _showSymbols ? key : _displayLetter(key), value: _showSymbols ? key : _displayLetter(key)))
            .toList(),
        entryFocusNode: widget.firstKeyFocusNode,
        entryKeyIndex: 0,
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
      ),
      SizedBox(height: spacing),
      _buildKeyRow(
        keys: rows[1]
            .map((key) => _KeyboardKeySpec.character(label: _showSymbols ? key : _displayLetter(key), value: _showSymbols ? key : _displayLetter(key)))
            .toList(),
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
        horizontalInset: 12,
      ),
      SizedBox(height: spacing),
      _buildKeyRow(
        keys: [
          _showSymbols
              ? _KeyboardKeySpec.action(label: _symbolPage == _SymbolPage.first ? '#+=' : '123', onTap: _toggleSymbolPage, flex: 18)
              : _KeyboardKeySpec.iconAction(
                  icon: _alphabeticCase == _AlphabeticCase.capsLock ? Icons.keyboard_capslock_rounded : Icons.arrow_upward_rounded,
                  onTap: _handleShiftPressed,
                  flex: 18,
                  isActive: _alphabeticCase != _AlphabeticCase.lower,
                ),
          ...rows[2].map((key) => _KeyboardKeySpec.character(label: _showSymbols ? key : _displayLetter(key), value: _showSymbols ? key : _displayLetter(key))),
          _KeyboardKeySpec.iconAction(icon: Icons.backspace_outlined, onTap: _backspace, flex: 18),
        ],
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
      ),
      SizedBox(height: spacing),
      _buildKeyRow(
        keys: widget.showDoneButton
            ? [
                _KeyboardKeySpec.action(label: _showSymbols ? 'ABC' : '?123', onTap: _toggleSymbolMode, flex: 19),
                _KeyboardKeySpec.character(label: ',', value: ',', flex: 10),
                _KeyboardKeySpec.action(label: 'space', onTap: () => _insertText(' '), flex: 48),
                _KeyboardKeySpec.character(label: '.', value: '.', flex: 10),
                _KeyboardKeySpec.action(label: widget.doneLabel, onTap: _handleDone, flex: 19),
              ]
            : [
                _KeyboardKeySpec.action(label: _showSymbols ? 'ABC' : '?123', onTap: _toggleSymbolMode, flex: 19),
                _KeyboardKeySpec.character(label: ',', value: ',', flex: 12),
                _KeyboardKeySpec.action(label: 'space', onTap: () => _insertText(' '), flex: 58),
                _KeyboardKeySpec.character(label: '.', value: '.', flex: 12),
              ],
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
      ),
    ];
  }

  List<Widget> _buildNumericRows({
    required double keyHeight,
    required double spacing,
    required double iconSize,
    required _ResolvedKeyboardPalette palette,
    required TextStyle? keyLabelStyle,
    required TextStyle? specialLabelStyle,
  }) {
    final shouldShowDecimalButton = widget.allowDecimal && widget.showDecimalButton;

    final bottomRow = <_KeyboardKeySpec>[
      if (widget.allowNegative)
        _KeyboardKeySpec.character(label: '-', value: '-')
      else if (shouldShowDecimalButton)
        _KeyboardKeySpec.character(label: '.', value: '.')
      else
        _KeyboardKeySpec.disabled(),
      _KeyboardKeySpec.character(label: '0', value: '0'),
      _KeyboardKeySpec.iconAction(icon: Icons.backspace_outlined, onTap: _backspace),
    ];

    return [
      _buildKeyRow(
        keys: const [
          _KeyboardKeySpec.character(label: '1', value: '1'),
          _KeyboardKeySpec.character(label: '2', value: '2'),
          _KeyboardKeySpec.character(label: '3', value: '3'),
        ],
        entryFocusNode: widget.firstKeyFocusNode,
        entryKeyIndex: 0,
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
      ),
      SizedBox(height: spacing),
      _buildKeyRow(
        keys: const [
          _KeyboardKeySpec.character(label: '4', value: '4'),
          _KeyboardKeySpec.character(label: '5', value: '5'),
          _KeyboardKeySpec.character(label: '6', value: '6'),
        ],
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
      ),
      SizedBox(height: spacing),
      _buildKeyRow(
        keys: const [
          _KeyboardKeySpec.character(label: '7', value: '7'),
          _KeyboardKeySpec.character(label: '8', value: '8'),
          _KeyboardKeySpec.character(label: '9', value: '9'),
        ],
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
      ),
      SizedBox(height: spacing),
      _buildKeyRow(
        keys: [bottomRow[0], bottomRow[1], bottomRow[2]],
        keyHeight: keyHeight,
        spacing: spacing,
        iconSize: iconSize,
        palette: palette,
        keyLabelStyle: keyLabelStyle,
        specialLabelStyle: specialLabelStyle,
        horizontalInset: 0,
      ),
      if (widget.showDoneButton) ...[
        SizedBox(height: spacing),
        _buildKeyRow(
          keys: [_KeyboardKeySpec.action(label: widget.doneLabel, onTap: _handleDone, flex: 1)],
          keyHeight: keyHeight + 2,
          spacing: spacing,
          iconSize: iconSize,
          palette: palette,
          keyLabelStyle: keyLabelStyle,
          specialLabelStyle: specialLabelStyle,
        ),
      ],
    ];
  }

  Widget _buildKeyRow({
    required List<_KeyboardKeySpec> keys,
    required double keyHeight,
    required double spacing,
    required double iconSize,
    required _ResolvedKeyboardPalette palette,
    required TextStyle? keyLabelStyle,
    required TextStyle? specialLabelStyle,
    FocusNode? entryFocusNode,
    int? entryKeyIndex,
    double horizontalInset = 0,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: Row(
        children: [
          for (var index = 0; index < keys.length; index++) ...[
            Expanded(
              flex: keys[index].flex,
              child: _KeyboardKeyButton(
                spec: keys[index],
                keyHeight: keyHeight,
                iconSize: iconSize,
                palette: palette,
                keyLabelStyle: keyLabelStyle,
                specialLabelStyle: specialLabelStyle,
                focusNode: index == entryKeyIndex ? entryFocusNode : null,
                borderRadius: widget.keyBorderRadius,
                enabled: widget.enabled,
                onCharacterTap: _insertText,
              ),
            ),
            if (index < keys.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

class _KeyboardKeyButton extends StatelessWidget {
  const _KeyboardKeyButton({
    required this.spec,
    required this.keyHeight,
    required this.iconSize,
    required this.palette,
    required this.keyLabelStyle,
    required this.specialLabelStyle,
    this.focusNode,
    required this.borderRadius,
    required this.enabled,
    required this.onCharacterTap,
  });

  final _KeyboardKeySpec spec;
  final double keyHeight;
  final double iconSize;
  final _ResolvedKeyboardPalette palette;
  final TextStyle? keyLabelStyle;
  final TextStyle? specialLabelStyle;
  final FocusNode? focusNode;
  final double borderRadius;
  final bool enabled;
  final ValueChanged<String> onCharacterTap;

  @override
  Widget build(BuildContext context) {
    if (spec.kind == _KeyboardKeyKind.disabled) {
      return SizedBox(height: keyHeight);
    }

    final isSpecial = spec.kind != _KeyboardKeyKind.character;
    final backgroundColor = spec.isActive ? palette.activeKey : (isSpecial ? palette.specialKey : palette.key);
    final foregroundColor = spec.isActive ? palette.activeText : (isSpecial ? palette.mutedText : palette.text);
    final focusedBackgroundColor = Color.alphaBlend(
      palette.activeKey.withValues(alpha: spec.isActive ? 0.2 : 0.12),
      backgroundColor,
    );

    VoidCallback? onTap;
    switch (spec.kind) {
      case _KeyboardKeyKind.character:
        onTap = enabled ? () => onCharacterTap(spec.value!) : null;
        break;
      case _KeyboardKeyKind.action:
      case _KeyboardKeyKind.iconAction:
        onTap = enabled ? spec.onTap : null;
        break;
      case _KeyboardKeyKind.disabled:
        onTap = null;
        break;
    }

    return SizedBox(
      height: keyHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: enabled ? 1 : 0.45,
        child: _RepeatableKeySurface(
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          focusedBackgroundColor: focusedBackgroundColor,
          foregroundColor: foregroundColor,
          onTap: onTap,
          focusNode: focusNode,
          enabled: enabled,
          enableRepeat: spec.kind == _KeyboardKeyKind.iconAction && spec.icon == Icons.backspace_outlined && enabled,
          child: Center(
            child: spec.icon != null
                ? Icon(spec.icon, size: iconSize, color: foregroundColor)
                : spec.subtitle != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        spec.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (isSpecial ? specialLabelStyle : keyLabelStyle)?.copyWith(color: foregroundColor),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        spec.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: specialLabelStyle?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.9),
                          fontSize: (specialLabelStyle?.fontSize ?? 13) - 2,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  )
                : Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (isSpecial ? specialLabelStyle : keyLabelStyle)?.copyWith(color: foregroundColor),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RepeatableKeySurface extends StatefulWidget {
  const _RepeatableKeySurface({
    required this.child,
    required this.borderRadius,
    required this.backgroundColor,
    required this.focusedBackgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.focusNode,
    required this.enabled,
    required this.enableRepeat,
  });

  final Widget child;
  final double borderRadius;
  final Color backgroundColor;
  final Color focusedBackgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool enabled;
  final bool enableRepeat;

  @override
  State<_RepeatableKeySurface> createState() => _RepeatableKeySurfaceState();
}

class _RepeatableKeySurfaceState extends State<_RepeatableKeySurface> {
  Timer? _repeatDelayTimer;
  Timer? _repeatTimer;

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  void _startRepeating() {
    if (!widget.enableRepeat || widget.onTap == null) return;
    _stopRepeating();
    _repeatDelayTimer = Timer(const Duration(milliseconds: 350), () {
      widget.onTap?.call();
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
        widget.onTap?.call();
      });
    });
  }

  void _stopRepeating() {
    _repeatDelayTimer?.cancel();
    _repeatTimer?.cancel();
    _repeatDelayTimer = null;
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.enableRepeat ? (_) => _startRepeating() : null,
      onLongPressEnd: widget.enableRepeat ? (_) => _stopRepeating() : null,
      onLongPressCancel: widget.enableRepeat ? _stopRepeating : null,
      child: TvFocusable(
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        onPressed: widget.onTap,
        builder: (context, focusState) {
          final isFocused = focusState.isFocused;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isFocused
                  ? widget.focusedBackgroundColor
                  : widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: isFocused
                    ? AppColors.focus
                    : Colors.transparent,
                width: isFocused ? 2 : 0,
              ),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.focusGlow,
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: widget.foregroundColor.withValues(alpha: 0.08),
                highlightColor: widget.foregroundColor.withValues(alpha: 0.06),
                child: Center(child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResolvedKeyboardPalette {
  const _ResolvedKeyboardPalette({
    required this.background,
    required this.key,
    required this.specialKey,
    required this.activeKey,
    required this.text,
    required this.mutedText,
    required this.activeText,
  });

  final Color background;
  final Color key;
  final Color specialKey;
  final Color activeKey;
  final Color text;
  final Color mutedText;
  final Color activeText;
}

enum _KeyboardKeyKind { character, action, iconAction, disabled }

class _KeyboardKeySpec {
  const _KeyboardKeySpec._({required this.kind, required this.label, this.value, this.subtitle, this.onTap, this.icon, this.flex = 10, this.isActive = false});

  final _KeyboardKeyKind kind;
  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? icon;
  final int flex;
  final bool isActive;

  const _KeyboardKeySpec.character({required String label, required String value, String? subtitle, int flex = 10})
    : this._(kind: _KeyboardKeyKind.character, label: label, value: value, subtitle: subtitle, flex: flex);

  const _KeyboardKeySpec.action({required String label, required VoidCallback onTap, int flex = 10})
    : this._(kind: _KeyboardKeyKind.action, label: label, onTap: onTap, flex: flex);

  const _KeyboardKeySpec.iconAction({required IconData icon, required VoidCallback onTap, int flex = 10, bool isActive = false})
    : this._(kind: _KeyboardKeyKind.iconAction, label: '', icon: icon, onTap: onTap, flex: flex, isActive: isActive);

  const _KeyboardKeySpec.disabled({int flex = 10}) : this._(kind: _KeyboardKeyKind.disabled, label: '', flex: flex);
}
