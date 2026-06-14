import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import 'data/remote_text_input_repository.dart';

class RemoteTextInputPage extends StatefulWidget {
  const RemoteTextInputPage({
    super.key,
    required this.sessionId,
    this.fallbackLabel,
  });

  final String sessionId;
  final String? fallbackLabel;

  @override
  State<RemoteTextInputPage> createState() => _RemoteTextInputPageState();
}

class _RemoteTextInputPageState extends State<RemoteTextInputPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode(
    debugLabel: 'remoteTextInput',
  );
  RemoteTextInputRepository? _repository;
  StreamSubscription<RemoteTextInputSnapshot>? _subscription;
  RemoteTextInputSnapshot? _snapshot;
  Timer? _writeDebounce;
  bool _applyingRemoteText = false;
  bool _isSubmittingAction = false;
  String? _pendingLocalText;
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
    unawaited(_loadInitialSession(repository));
  }

  @override
  void dispose() {
    _controller.removeListener(_handleLocalTextChanged);
    _controller.dispose();
    _textFieldFocusNode.dispose();
    _writeDebounce?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = _snapshot;
    final isMissing = snapshot != null && !snapshot.exists;
    final isConnected = snapshot != null && snapshot.exists;
    final fieldLabel = _fieldLabelFor(snapshot);

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
                          : isConnected
                          ? 'Typing here updates the focused TV field live.'
                          : 'Choose Scan QR on the TV and keep the QR code visible.',
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
                        fieldLabel,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _textFieldFocusNode,
                              autofocus: true,
                              keyboardType: TextInputType.text,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: fieldLabel,
                                hintText: 'Type the value',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.filledTonal(
                            onPressed: _pasteFromClipboard,
                            tooltip: 'Paste',
                            icon: const Icon(Icons.content_paste_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _isSubmittingAction
                            ? null
                            : () => _submitAction(snapshot),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(snapshot.actionLabel),
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

    if (!snapshot.exists) {
      return;
    }

    if (_shouldHoldLocalText(snapshot)) {
      return;
    }

    if (snapshot.text == _controller.text) {
      if (_pendingLocalText == snapshot.text) {
        _pendingLocalText = null;
      }
      _ensureTextFieldFocus(snapshot);
      return;
    }

    _applyingRemoteText = true;
    _controller.value = TextEditingValue(
      text: snapshot.text,
      selection: TextSelection.collapsed(offset: snapshot.text.length),
    );
    _applyingRemoteText = false;

    _ensureTextFieldFocus(snapshot);
  }

  Future<void> _loadInitialSession(RemoteTextInputRepository repository) async {
    try {
      final snapshot = await repository
          .getSession(widget.sessionId)
          .timeout(const Duration(seconds: 8));
      if (mounted && _snapshot == null) {
        _handleSnapshot(snapshot);
      }
    } on TimeoutException {
      if (mounted && _snapshot == null) {
        setState(
          () => _errorMessage =
              'Could not connect to the TV input session. Keep the QR code visible on the TV and try scanning again.',
        );
      }
    } catch (error) {
      if (mounted && _snapshot == null) {
        setState(() => _errorMessage = error.toString());
      }
    }
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
        _applyingRemoteText) {
      return;
    }

    _pendingLocalText = _controller.text;
    _writeDebounce?.cancel();
    _writeDebounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(
        repository.updateText(
          sessionId: widget.sessionId,
          text: _controller.text,
        ),
      );
    });
  }

  Future<void> _pasteFromClipboard() async {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.exists) {
      return;
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      return;
    }

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _pendingLocalText = text;
    _ensureTextFieldFocus(snapshot);
  }

  void _ensureTextFieldFocus(RemoteTextInputSnapshot snapshot) {
    if (!snapshot.exists || _textFieldFocusNode.hasFocus) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && snapshot == _snapshot && snapshot.exists) {
        _textFieldFocusNode.requestFocus();
      }
    });
  }

  bool _shouldHoldLocalText(RemoteTextInputSnapshot snapshot) {
    final pendingLocalText = _pendingLocalText;
    if (pendingLocalText == null || !_textFieldFocusNode.hasFocus) {
      return false;
    }
    return snapshot.text != pendingLocalText;
  }

  Future<void> _submitAction(RemoteTextInputSnapshot snapshot) async {
    final repository = _repository;
    if (repository == null || !snapshot.exists || _isSubmittingAction) {
      return;
    }

    setState(() => _isSubmittingAction = true);
    try {
      _writeDebounce?.cancel();
      _pendingLocalText = _controller.text;
      await repository.updateText(
        sessionId: widget.sessionId,
        text: _controller.text,
      );
      await repository.submitAction(
        sessionId: widget.sessionId,
        text: _controller.text,
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

  String _fieldLabelFor(RemoteTextInputSnapshot? snapshot) {
    final label = snapshot?.label.trim();
    if (label != null && label.isNotEmpty && label != 'Focused TV field') {
      return label;
    }
    final fallbackLabel = widget.fallbackLabel?.trim();
    if (fallbackLabel != null && fallbackLabel.isNotEmpty) {
      return fallbackLabel;
    }
    return 'Focused TV field';
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
