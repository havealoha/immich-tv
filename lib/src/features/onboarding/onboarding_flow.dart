import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_environment.dart';
import '../../core/errors/app_exception.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/server_repository.dart';
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
  final _serverController = TextEditingController(
    text: 'http://192.168.0.243:2283',
  );
  final _emailController = TextEditingController(
    text: 'afridi.khondakar@gmail.com',
  );
  final _passwordController = TextEditingController(text: '#Noobshit911');
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _serverFieldFocusNode = FocusNode(debugLabel: 'serverField');
  final _emailFieldFocusNode = FocusNode(debugLabel: 'emailField');
  final _passwordFieldFocusNode = FocusNode(debugLabel: 'passwordField');
  late final List<TextEditingController> _pinDigitControllers;
  late final List<TextEditingController> _confirmPinDigitControllers;
  late final List<FocusNode> _pinDigitFocusNodes;
  late final List<FocusNode> _confirmPinDigitFocusNodes;
  final _actionButtonFocusNode = FocusNode(debugLabel: 'primaryAction');
  bool _hasAppliedInitialValues = false;
  bool _isConfirmingPin = false;

  FocusNode get _pinFieldFocusNode => _pinDigitFocusNodes.first;
  FocusNode get _confirmPinFieldFocusNode => _confirmPinDigitFocusNodes.first;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAppliedInitialValues) {
      return;
    }

    final useMockServices = context.read<AppEnvironment>().useMockServices;
    _serverController.text = useMockServices
        ? 'https://demo.immichtv.local'
        : 'http://192.168.0.243:2283';
    _emailController.text = useMockServices
        ? 'livingroom@demo.immichtv'
        : 'afridi.khondakar@gmail.com';
    _passwordController.text = useMockServices
        ? 'demo-password'
        : '#Noobshit911';
    _hasAppliedInitialValues = true;
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
    for (final focusNode in _pinDigitFocusNodes) {
      focusNode.dispose();
    }
    for (final focusNode in _confirmPinDigitFocusNodes) {
      focusNode.dispose();
    }
    _actionButtonFocusNode.dispose();
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
                isTvLayout: MediaQuery.sizeOf(context).width >= 1600,
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
                actionButtonFocusNode: _actionButtonFocusNode,
                isConfirmingPin: _isConfirmingPin,
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

    final pin = _joinDigits(_pinDigitControllers);
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

    final confirmedPin = _joinDigits(_confirmPinDigitControllers);
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

    appFlowCubit.completeSignIn(session);
  }

  String _joinDigits(List<TextEditingController> controllers) =>
      controllers.map((controller) => controller.text).join();

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
  }
}
