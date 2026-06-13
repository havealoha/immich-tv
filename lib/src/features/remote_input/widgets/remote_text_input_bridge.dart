import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../data/remote_text_input_repository.dart';

class RemoteTextInputBridge extends StatefulWidget {
  const RemoteTextInputBridge({
    super.key,
    required this.scopeId,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.numericOnly = false,
    this.maxLength,
    this.enabled = true,
    this.actionLabel,
    this.onRemoteAction,
  });

  final String scopeId;
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool numericOnly;
  final int? maxLength;
  final bool enabled;
  final String? actionLabel;
  final VoidCallback? onRemoteAction;

  @override
  State<RemoteTextInputBridge> createState() => _RemoteTextInputBridgeState();
}

class _RemoteTextInputBridgeState extends State<RemoteTextInputBridge>
    with WidgetsBindingObserver {
  static final Map<String, RemoteTextInputSession> _sessionsByScope = {};

  late final String _ownerId = '${DateTime.now().microsecondsSinceEpoch}';
  RemoteTextInputRepository? _repository;
  RemoteTextInputSession? _session;
  StreamSubscription<RemoteTextInputSnapshot>? _subscription;
  Timer? _writeDebounce;
  bool _applyingRemoteText = false;
  String? _lastHandledActionId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_handleLocalTextChanged);
    _startSession();
  }

  @override
  void didUpdateWidget(RemoteTextInputBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleLocalTextChanged);
      widget.controller.addListener(_handleLocalTextChanged);
      _restartSession();
      return;
    }

    if (oldWidget.label != widget.label ||
        oldWidget.obscureText != widget.obscureText ||
        oldWidget.numericOnly != widget.numericOnly ||
        oldWidget.maxLength != widget.maxLength ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.actionLabel != widget.actionLabel) {
      _restartSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_handleLocalTextChanged);
    _writeDebounce?.cancel();
    _subscription?.cancel();
    if (_shouldDeleteForLifecycle(WidgetsBinding.instance.lifecycleState)) {
      _deleteSession();
    } else {
      _disableActiveField();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_shouldDeleteForLifecycle(state)) {
      _deleteSession();
      return;
    }

    if (state == AppLifecycleState.paused) {
      _disableActiveField();
      return;
    }

    if (state == AppLifecycleState.resumed && mounted) {
      final session = _session;
      final repository = _repository;
      if (session == null || repository == null) {
        _startSession();
      } else {
        unawaited(_publishActiveField(repository, session));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _session;

    if (_repository == null) {
      return const _RemoteInputStatusCard(
        icon: Icons.cloud_off_outlined,
        title: 'Phone input unavailable',
        message: 'Firebase is not initialized in this runtime.',
      );
    }

    if (_errorMessage != null) {
      return _RemoteInputStatusCard(
        icon: Icons.sync_problem_rounded,
        title: 'Could not create phone input',
        message: _errorMessage!,
      );
    }

    if (session == null) {
      return const _RemoteInputStatusCard(
        icon: Icons.qr_code_2_rounded,
        title: 'Preparing phone input',
        message: 'Creating a secure temporary input link...',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                data: session.url,
                version: QrVersions.auto,
                size: 112,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Type ${session.label} on your phone',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Scan this code to open typing on your phone. You can enter text there instead of using the TV remote. Scan once, then keep the page open as you move between fields.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  session.url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    final repository = RemoteTextInputRepository.tryCreate();
    if (!mounted) {
      return;
    }
    if (repository == null) {
      setState(() => _repository = null);
      return;
    }

    setState(() {
      _repository = repository;
      _session = null;
      _errorMessage = null;
    });

    try {
      final session =
          _sessionsByScope[widget.scopeId] ??
          await repository.createSession(
            label: widget.label,
            initialText: widget.controller.text,
            obscureText: widget.obscureText,
            numericOnly: widget.numericOnly,
            maxLength: widget.maxLength,
            actionLabel: widget.actionLabel,
            ownerId: _ownerId,
          );
      _sessionsByScope[widget.scopeId] = session;
      if (!mounted) {
        return;
      }

      setState(() => _session = session);
      unawaited(_publishActiveField(repository, session));
      _subscription = repository.watchSession(session.id).listen((snapshot) {
        if (!snapshot.exists ||
            !snapshot.enabled ||
            snapshot.ownerId != _ownerId ||
            _applyingRemoteText) {
          return;
        }
        final actionId = snapshot.actionId;
        if (actionId != null && actionId != _lastHandledActionId) {
          _lastHandledActionId = actionId;
          widget.onRemoteAction?.call();
        }
        if (snapshot.text == widget.controller.text) {
          return;
        }
        _applyingRemoteText = true;
        widget.controller.value = TextEditingValue(
          text: snapshot.text,
          selection: TextSelection.collapsed(offset: snapshot.text.length),
        );
        _applyingRemoteText = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    }
  }

  Future<void> _publishActiveField(
    RemoteTextInputRepository repository,
    RemoteTextInputSession session,
  ) async {
    try {
      await repository.updateActiveField(
        sessionId: session.id,
        label: widget.label,
        text: widget.controller.text,
        obscureText: widget.obscureText,
        numericOnly: widget.numericOnly,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        ownerId: _ownerId,
        actionLabel: widget.actionLabel,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    }
  }

  void _restartSession() {
    _writeDebounce?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _session = null;
    _startSession();
  }

  void _disableActiveField() {
    final session = _session;
    final repository = _repository;
    if (session == null || repository == null) {
      return;
    }

    unawaited(
      repository
          .updateActiveField(
            sessionId: session.id,
            label: widget.label,
            text: '',
            obscureText: widget.obscureText,
            numericOnly: widget.numericOnly,
            maxLength: widget.maxLength,
            enabled: false,
            ownerId: _ownerId,
            actionLabel: null,
          )
          .catchError((_) {}),
    );
  }

  void _deleteSession() {
    final session = _session ?? _sessionsByScope[widget.scopeId];
    final repository = _repository;
    _subscription?.cancel();
    _subscription = null;
    _session = null;

    if (session == null || repository == null) {
      return;
    }

    if (_sessionsByScope[widget.scopeId]?.id == session.id) {
      _sessionsByScope.remove(widget.scopeId);
    }

    unawaited(repository.deleteSession(session.id).catchError((_) {}));
  }

  bool _shouldDeleteForLifecycle(AppLifecycleState? state) {
    return state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
  }

  void _handleLocalTextChanged() {
    if (_applyingRemoteText || !widget.enabled) {
      return;
    }

    final session = _session;
    final repository = _repository;
    if (session == null || repository == null) {
      return;
    }

    _writeDebounce?.cancel();
    _writeDebounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(
        repository.updateText(
          sessionId: session.id,
          text: widget.controller.text,
          numericOnly: widget.numericOnly,
          maxLength: widget.maxLength,
        ),
      );
    });
  }
}

class _RemoteInputStatusCard extends StatelessWidget {
  const _RemoteInputStatusCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
