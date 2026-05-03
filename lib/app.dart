import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import 'src/core/repositories/auth_repository.dart';
import 'src/core/repositories/media_repository.dart';
import 'src/core/repositories/server_repository.dart';
import 'src/core/services/server_url_normalizer.dart';
import 'src/features/auth/data/immich_auth_repository.dart';
import 'src/app_shell.dart';
import 'src/features/app_flow/cubit/app_flow_cubit.dart';
import 'src/features/library/data/immich_media_repository.dart';
import 'src/features/onboarding/data/immich_server_repository.dart';
import 'src/platform/storage/platform_session_storage.dart';
import 'src/shared/presentation/app_colors.dart';
import 'src/shared/presentation/app_radii.dart';

void runImmichTvApp() {
  runApp(ImmichTvApp());
}

class ImmichTvApp extends StatelessWidget {
  ImmichTvApp({
    super.key,
    AuthRepository? authRepository,
    ServerRepository? serverRepository,
    MediaRepository? mediaRepository,
  }) : _authRepository =
           authRepository ??
           ImmichAuthRepository(
             dio: Dio(
               BaseOptions(
                 connectTimeout: const Duration(seconds: 8),
                 receiveTimeout: const Duration(seconds: 8),
                 sendTimeout: const Duration(seconds: 8),
               ),
             ),
             sessionStorage: PlatformSessionStorage(),
           ),
       _serverRepository =
           serverRepository ??
           ImmichServerRepository(
             dio: Dio(
               BaseOptions(
                 connectTimeout: const Duration(seconds: 8),
                 receiveTimeout: const Duration(seconds: 8),
                 sendTimeout: const Duration(seconds: 8),
               ),
             ),
             normalizer: const ServerUrlNormalizer(),
           ),
       _mediaRepository =
           mediaRepository ??
           ImmichMediaRepository(
             dio: Dio(
               BaseOptions(
                 connectTimeout: const Duration(seconds: 8),
                 receiveTimeout: const Duration(seconds: 8),
                 sendTimeout: const Duration(seconds: 8),
               ),
             ),
           );

  final AuthRepository _authRepository;
  final ServerRepository _serverRepository;
  final MediaRepository _mediaRepository;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.focus,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<ServerRepository>.value(value: _serverRepository),
        RepositoryProvider<MediaRepository>.value(value: _mediaRepository),
      ],
      child: MaterialApp(
        title: 'ImmichTV',
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          cardTheme: baseTheme.cardTheme.copyWith(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.focus, width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFFB6D6D4)),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              backgroundColor: AppColors.focus,
              foregroundColor: AppColors.actionForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
        ),
        home: BlocProvider(
          create: (_) => AppFlowCubit(_authRepository)..initialize(),
          child: const AppShell(),
        ),
      ),
    );
  }
}
