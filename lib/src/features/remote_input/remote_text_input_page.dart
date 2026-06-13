import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import 'data/remote_text_input_repository.dart';

class RemoteTextInputPage extends StatefulWidget {
  const RemoteTextInputPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<RemoteTextInputPage> createState() => _RemoteTextInputPageState();
}

class _RemoteTextInputPageState extends State<RemoteTextInputPage> {
  final TextEditingController _controller = TextEditingController();
  RemoteTextInputRepository? _repository;
  StreamSubscription<RemoteTextInputSnapshot>? _subscription;
  RemoteTextInputSnapshot? _snapshot;
  Timer? _writeDebounce;
  bool _applyingRemoteText = false;
  bool _isSubmittingAction = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleLocalTextChanged);
    _repository = RemoteTextInputRepository.tryCreate();
    final repository = _repository;
    if (repository == null) {
      _errorMessage = 'Firebase is not initialized for this page.';
      return;
    }
    _subscription = repository
        .watchSession(widget.sessionId)
        .listen(
          _handleSnapshot,
          onError: (Object error) {
            if (mounted) {
              setState(() => _errorMessage = error.toString());
            }
          },
        );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleLocalTextChanged);
    _controller.dispose();
    _writeDebounce?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = _snapshot;
    final isMissing = snapshot != null && !snapshot.exists;
    final isInputEnabled =
        snapshot != null && snapshot.exists && snapshot.enabled;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Immich TV phone input',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isMissing
                          ? 'This input session has expired. Scan the QR code on the TV again.'
                          : isInputEnabled
                          ? 'Typing here updates the focused TV field live.'
                          : 'Choose Scan QR and focus a field on the TV to type from this page.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_errorMessage != null)
                      _StatusBanner(
                        color: AppColors.error,
                        message: _errorMessage!,
                      )
                    else if (snapshot == null)
                      const _StatusBanner(
                        color: AppColors.info,
                        message: 'Connecting to the TV input session...',
                      )
                    else if (isMissing)
                      const _StatusBanner(
                        color: AppColors.warning,
                        message: 'Session not found.',
                      )
                    else if (!snapshot.enabled)
                      _StatusBanner(
                        color: AppColors.warning,
                        message:
                            'Phone input is paused. Switch the TV typing method to Scan QR and focus a field.',
                      )
                    else ...[
                      Text(
                        'Entering text into',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        snapshot.label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        enabled: snapshot.enabled,
                        obscureText: snapshot.obscureText,
                        keyboardType: snapshot.numericOnly
                            ? TextInputType.number
                            : TextInputType.text,
                        inputFormatters: [
                          if (snapshot.numericOnly)
                            FilteringTextInputFormatter.digitsOnly,
                          if (snapshot.maxLength != null)
                            LengthLimitingTextInputFormatter(
                              snapshot.maxLength,
                            ),
                        ],
                        minLines: 1,
                        maxLines: snapshot.obscureText ? 1 : 4,
                        decoration: InputDecoration(
                          labelText: snapshot.label,
                          hintText: snapshot.numericOnly
                              ? 'Enter numbers'
                              : 'Type the value',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _isSubmittingAction
                            ? null
                            : () => _submitAction(_actionLabelFor(snapshot)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(_actionLabelFor(snapshot)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Keep this page open until the TV advances to the next step.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
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

  void _handleSnapshot(RemoteTextInputSnapshot snapshot) {
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _errorMessage = null;
    });

    if (!snapshot.exists || snapshot.text == _controller.text) {
      return;
    }

    _applyingRemoteText = true;
    _controller.value = TextEditingValue(
      text: snapshot.text,
      selection: TextSelection.collapsed(offset: snapshot.text.length),
    );
    _applyingRemoteText = false;
  }

  void _handleLocalTextChanged() {
    if (_applyingRemoteText) {
      return;
    }
    final repository = _repository;
    final snapshot = _snapshot;
    if (repository == null ||
        snapshot == null ||
        !snapshot.exists ||
        !snapshot.enabled) {
      return;
    }

    _writeDebounce?.cancel();
    _writeDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(
        repository.updateText(
          sessionId: widget.sessionId,
          text: _controller.text,
          numericOnly: snapshot.numericOnly,
          maxLength: snapshot.maxLength,
        ),
      );
    });
  }

  Future<void> _submitAction(String actionLabel) async {
    final repository = _repository;
    final snapshot = _snapshot;
    if (repository == null ||
        snapshot == null ||
        !snapshot.exists ||
        !snapshot.enabled) {
      return;
    }

    setState(() => _isSubmittingAction = true);
    try {
      _writeDebounce?.cancel();
      await repository.updateText(
        sessionId: widget.sessionId,
        text: _controller.text,
        numericOnly: snapshot.numericOnly,
        maxLength: snapshot.maxLength,
      );
      await repository.submitAction(
        sessionId: widget.sessionId,
        actionLabel: actionLabel,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingAction = false);
      }
    }
  }

  String _actionLabelFor(RemoteTextInputSnapshot snapshot) {
    final configuredLabel = snapshot.actionLabel?.trim();
    if (configuredLabel != null && configuredLabel.isNotEmpty) {
      return configuredLabel;
    }

    final label = snapshot.label.toLowerCase();
    if (label.contains('password') || label.contains('api key')) {
      return 'Continue';
    }
    if (label.contains('server') || label.contains('email')) {
      return 'Next';
    }
    return 'Done';
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.color, required this.message});

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(message),
    );
  }
}
