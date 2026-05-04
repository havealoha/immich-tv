import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_environment.dart';
import '../../core/errors/app_exception.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/server_repository.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import 'cubit/onboarding_cubit.dart';
import 'cubit/onboarding_state.dart';
import 'widgets/onboarding_branding.dart';
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
  final _pinFieldFocusNode = FocusNode(debugLabel: 'pinField');
  final _confirmPinFieldFocusNode = FocusNode(debugLabel: 'confirmPinField');
  final _actionButtonFocusNode = FocusNode(debugLabel: 'primaryAction');
  bool _hasAppliedInitialValues = false;

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
    _serverFieldFocusNode.dispose();
    _emailFieldFocusNode.dispose();
    _passwordFieldFocusNode.dispose();
    _pinFieldFocusNode.dispose();
    _confirmPinFieldFocusNode.dispose();
    _actionButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => OnboardingCubit(
        authRepository: context.read<AuthRepository>(),
        serverRepository: context.read<ServerRepository>(),
      ),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listenWhen: (previous, current) => previous.step != current.step,
        listener: (context, state) {
          if (state.step == OnboardingStep.credentials) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _emailFieldFocusNode.requestFocus();
              }
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _serverFieldFocusNode.requestFocus();
              }
            });
          }
        },
        child: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final useMockServices = context
                .read<AppEnvironment>()
                .useMockServices;
            final hasSavedProfiles = context
                .watch<AppFlowCubit>()
                .state
                .profiles
                .isNotEmpty;

            return OnboardingShell(
              branding: OnboardingBranding(theme: theme, state: state),
              child: OnboardingForm(
                theme: theme,
                state: state,
                isTvLayout: MediaQuery.sizeOf(context).width >= 1600,
                useMockServices: useMockServices,
                hasSavedProfiles: hasSavedProfiles,
                serverController: _serverController,
                emailController: _emailController,
                passwordController: _passwordController,
                pinController: _pinController,
                confirmPinController: _confirmPinController,
                serverFieldFocusNode: _serverFieldFocusNode,
                emailFieldFocusNode: _emailFieldFocusNode,
                passwordFieldFocusNode: _passwordFieldFocusNode,
                pinFieldFocusNode: _pinFieldFocusNode,
                confirmPinFieldFocusNode: _confirmPinFieldFocusNode,
                actionButtonFocusNode: _actionButtonFocusNode,
                onPrimaryAction: () => _handlePrimaryAction(context, state),
                onChangeServer: () =>
                    context.read<OnboardingCubit>().returnToServerStep(),
                onShowProfiles: () =>
                    context.read<AppFlowCubit>().showProfilePicker(),
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

    if (!state.hasValidatedServer) {
      await onboardingCubit.validateServer(_serverController.text);
      return;
    }

    final pin = _pinController.text.trim();
    final confirmedPin = _confirmPinController.text.trim();
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
      messenger.showSnackBar(
        const SnackBar(content: Text('The PIN confirmation did not match.')),
      );
      _confirmPinFieldFocusNode.requestFocus();
      return;
    }

    final session = await onboardingCubit.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted || session == null) {
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
}
