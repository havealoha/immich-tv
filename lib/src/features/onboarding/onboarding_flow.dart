import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/demo_mode.dart';
import '../../core/config/app_environment.dart';
import '../../core/errors/app_exception.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/server_repository.dart';
import '../../shared/presentation/app_breakpoints.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';
import 'widgets/onboarding_form.dart';
import 'widgets/onboarding_shell.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _serverController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _serverFieldFocusNode = FocusNode(debugLabel: 'serverField');
  final _emailFieldFocusNode = FocusNode(debugLabel: 'emailField');
  final _passwordFieldFocusNode = FocusNode(debugLabel: 'passwordField');
  final _serverKeyboardFocusNode = FocusNode(debugLabel: 'serverKeyboard');
  final _emailKeyboardFocusNode = FocusNode(debugLabel: 'emailKeyboard');
  final _passwordKeyboardFocusNode = FocusNode(
    debugLabel: 'passwordKeyboard',
  );
  final _pinKeyboardFocusNode = FocusNode(debugLabel: 'pinKeyboard');
  final _confirmPinKeyboardFocusNode = FocusNode(
    debugLabel: 'confirmPinKeyboard',
  );
  late final List<TextEditingController> _pinDigitControllers;
  late final List<TextEditingController> _confirmPinDigitControllers;
  late final List<FocusNode> _pinDigitFocusNodes;
  late final List<FocusNode> _confirmPinDigitFocusNodes;
  bool _isConfirmingPin = false;
  OnboardingKeyboardField? _activeKeyboardField =
      OnboardingKeyboardField.server;

  FocusNode get _pinFieldFocusNode => _pinDigitFocusNodes.first;
  FocusNode get _confirmPinFieldFocusNode => _confirmPinDigitFocusNodes.first;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _serverController.text = DemoMode.serverUrl;
      _emailController.text = DemoMode.email;
      _passwordController.text = DemoMode.password;
    }
    _pinDigitControllers = List.generate(4, (_) => TextEditingController());
    _confirmPinDigitControllers = List.generate(
      4,
      (_) => TextEditingController(),
    );
    _pinDigitFocusNodes = List.generate(
      4,
      (index) => FocusNode(debugLabel: 'pinField.$index'),
    );
    _confirmPinDigitFocusNodes = List.generate(
      4,
      (index) => FocusNode(debugLabel: 'confirmPinField.$index'),
    );
    _serverFieldFocusNode.addListener(_handleKeyboardFocusChange);
    _emailFieldFocusNode.addListener(_handleKeyboardFocusChange);
    _passwordFieldFocusNode.addListener(_handleKeyboardFocusChange);
    _pinFieldFocusNode.addListener(_handleKeyboardFocusChange);
    _confirmPinFieldFocusNode.addListener(_handleKeyboardFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _serverFieldFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    for (final controller in _pinDigitControllers) {
      controller.dispose();
    }
    for (final controller in _confirmPinDigitControllers) {
      controller.dispose();
    }
    _serverFieldFocusNode.dispose();
    _emailFieldFocusNode.dispose();
    _passwordFieldFocusNode.dispose();
    _serverKeyboardFocusNode.dispose();
    _emailKeyboardFocusNode.dispose();
    _passwordKeyboardFocusNode.dispose();
    _pinKeyboardFocusNode.dispose();
    _confirmPinKeyboardFocusNode.dispose();
    for (final focusNode in _pinDigitFocusNodes) {
      focusNode.dispose();
    }
    for (final focusNode in _confirmPinDigitFocusNodes) {
      focusNode.dispose();
    }
    _serverFieldFocusNode.removeListener(_handleKeyboardFocusChange);
    _emailFieldFocusNode.removeListener(_handleKeyboardFocusChange);
    _passwordFieldFocusNode.removeListener(_handleKeyboardFocusChange);
    _pinFieldFocusNode.removeListener(_handleKeyboardFocusChange);
    _confirmPinFieldFocusNode.removeListener(_handleKeyboardFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(
        authRepository: context.read<AuthRepository>(),
        serverRepository: context.read<ServerRepository>(),
      ),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listenWhen: (previous, current) => previous.step != current.step,
        listener: (context, state) {
          if (state.step == OnboardingStep.pin) {
            _resetPinSetup();
          }
          final targetFocusNode = switch (state.step) {
            OnboardingStep.server => _serverFieldFocusNode,
            OnboardingStep.credentials => _emailFieldFocusNode,
            OnboardingStep.pin =>
              _isConfirmingPin ? _confirmPinFieldFocusNode : _pinFieldFocusNode,
          };
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              targetFocusNode.requestFocus();
            }
          });
        },
        child: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final useMockServices = context
                .read<AppEnvironment>()
                .useMockServices;

            return OnboardingShell(
              child: OnboardingForm(
                theme: Theme.of(context),
                state: state,
                isTvLayout:
                    MediaQuery.sizeOf(context).width >=
                    AppBreakpoints.desktop,
                useMockServices: useMockServices,
                serverController: _serverController,
                emailController: _emailController,
                passwordController: _passwordController,
                pinController: _pinController,
                confirmPinController: _confirmPinController,
                pinDigitControllers: _pinDigitControllers,
                confirmPinDigitControllers: _confirmPinDigitControllers,
                pinDigitFocusNodes: _pinDigitFocusNodes,
                confirmPinDigitFocusNodes: _confirmPinDigitFocusNodes,
                serverFieldFocusNode: _serverFieldFocusNode,
                emailFieldFocusNode: _emailFieldFocusNode,
                passwordFieldFocusNode: _passwordFieldFocusNode,
                pinFieldFocusNode: _pinFieldFocusNode,
                confirmPinFieldFocusNode: _confirmPinFieldFocusNode,
                serverKeyboardFocusNode: _serverKeyboardFocusNode,
                emailKeyboardFocusNode: _emailKeyboardFocusNode,
                passwordKeyboardFocusNode: _passwordKeyboardFocusNode,
                pinKeyboardFocusNode: _pinKeyboardFocusNode,
                confirmPinKeyboardFocusNode: _confirmPinKeyboardFocusNode,
                isConfirmingPin: _isConfirmingPin,
                activeKeyboardField: _activeKeyboardField,
                onPrimaryAction: () => _handlePrimaryAction(context, state),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    OnboardingState state,
  ) async {
    final onboardingCubit = context.read<OnboardingCubit>();
    final appFlowCubit = context.read<AppFlowCubit>();
    final authRepository = context.read<AuthRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (state.step == OnboardingStep.server) {
      await onboardingCubit.validateServer(_serverController.text);
      return;
    }

    if (state.step == OnboardingStep.credentials) {
      await onboardingCubit.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return;
    }

    final session = state.pendingSession;
    if (session == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in before setting up a PIN.')),
      );
      return;
    }

    final pin = _currentPinValue(
      controller: _pinController,
      digitControllers: _pinDigitControllers,
    );
    if (!_isConfirmingPin) {
      if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter a 4-digit PIN to continue.')),
        );
        _focusFirstIncomplete(_pinDigitControllers, _pinDigitFocusNodes);
        return;
      }

      _pinController.text = pin;
      setState(() {
        _isConfirmingPin = true;
        for (final controller in _confirmPinDigitControllers) {
          controller.clear();
        }
        _confirmPinController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confirmPinFieldFocusNode.requestFocus();
        }
      });
      return;
    }

    final confirmedPin = _currentPinValue(
      controller: _confirmPinController,
      digitControllers: _confirmPinDigitControllers,
    );
    _confirmPinController.text = confirmedPin;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Enter a 4-digit PIN to save this profile.'),
        ),
      );
      _pinFieldFocusNode.requestFocus();
      return;
    }

    if (pin != confirmedPin) {
      for (final controller in _confirmPinDigitControllers) {
        controller.clear();
      }
      _confirmPinController.clear();
      messenger.showSnackBar(
        const SnackBar(content: Text('The PIN confirmation did not match.')),
      );
      _confirmPinFieldFocusNode.requestFocus();
      return;
    }

    try {
      await authRepository.saveProfile(
        session: session,
        password: _passwordController.text,
        pin: pin,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final rawMessage = error is AppException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '');
      messenger.showSnackBar(SnackBar(content: Text(rawMessage)));
      return;
    }

    await appFlowCubit.completeSignIn(session);
  }

  String _joinDigits(List<TextEditingController> controllers) =>
      controllers.map((controller) => controller.text).join();

  String _currentPinValue({
    required TextEditingController controller,
    required List<TextEditingController> digitControllers,
  }) {
    final controllerValue = controller.text.trim();
    if (controllerValue.isNotEmpty) {
      return controllerValue;
    }
    return _joinDigits(digitControllers);
  }

  void _focusFirstIncomplete(
    List<TextEditingController> controllers,
    List<FocusNode> focusNodes,
  ) {
    for (var i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty) {
        focusNodes[i].requestFocus();
        return;
      }
    }
    focusNodes.first.requestFocus();
  }

  void _resetPinSetup() {
    _pinController.clear();
    _confirmPinController.clear();
    for (final controller in _pinDigitControllers) {
      controller.clear();
    }
    for (final controller in _confirmPinDigitControllers) {
      controller.clear();
    }
    _isConfirmingPin = false;
    _activeKeyboardField = OnboardingKeyboardField.pin;
  }

  void _handleKeyboardFocusChange() {
    final nextField = _focusedKeyboardField;
    if (nextField == null || nextField == _activeKeyboardField) {
      return;
    }
    setState(() {
      _activeKeyboardField = nextField;
    });
  }

  OnboardingKeyboardField? get _focusedKeyboardField {
    if (_serverFieldFocusNode.hasFocus) {
      return OnboardingKeyboardField.server;
    }
    if (_emailFieldFocusNode.hasFocus) {
      return OnboardingKeyboardField.email;
    }
    if (_passwordFieldFocusNode.hasFocus) {
      return OnboardingKeyboardField.password;
    }
    if (_confirmPinFieldFocusNode.hasFocus) {
      return OnboardingKeyboardField.confirmPin;
    }
    if (_pinFieldFocusNode.hasFocus) {
      return OnboardingKeyboardField.pin;
    }
    return null;
  }
}
