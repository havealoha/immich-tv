import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/core/config/app_environment.dart';
import 'src/core/network/immich_dio_factory.dart';
import 'src/core/repositories/auth_repository.dart';
import 'src/core/repositories/asset_image_repository.dart';
import 'src/core/repositories/media_repository.dart';
import 'src/core/repositories/server_repository.dart';
import 'src/core/services/server_url_normalizer.dart';
import 'src/features/auth/data/immich_auth_repository.dart';
import 'src/app_shell.dart';
import 'src/features/app_flow/cubit/app_flow_cubit.dart';
import 'src/features/library/data/immich_asset_image_repository.dart';
import 'src/features/library/data/immich_media_repository.dart';
import 'src/features/mock/data/mock_auth_repository.dart';
import 'src/features/mock/data/mock_media_repository.dart';
import 'src/features/mock/data/mock_server_repository.dart';
import 'src/features/onboarding/data/immich_server_repository.dart';
import 'src/platform/storage/platform_profile_storage.dart';
import 'src/shared/presentation/app_colors.dart';
import 'src/shared/presentation/app_radii.dart';

void runImmichTvApp() {
  runApp(ImmichTvApp());
}

class ImmichTvApp extends StatelessWidget {
  ImmichTvApp({
    super.key,
    AuthRepository? authRepository,
    AssetImageRepository? assetImageRepository,
    ServerRepository? serverRepository,
    MediaRepository? mediaRepository,
    bool? useMockServices,
  }) : _environment = AppEnvironment(useMockServices: useMockServices ?? false),
       _authRepository =
           authRepository ??
           ((useMockServices ?? false)
               ? MockAuthRepository(profileStorage: PlatformProfileStorage())
               : ImmichAuthRepository(
                   dio: ImmichDioFactory.create(),
                   profileStorage: PlatformProfileStorage(),
                 )),
       _serverRepository =
           serverRepository ??
           ((useMockServices ?? false)
               ? MockServerRepository(normalizer: const ServerUrlNormalizer())
               : ImmichServerRepository(
                   dio: ImmichDioFactory.create(),
                   normalizer: const ServerUrlNormalizer(),
                 )),
       _assetImageRepository =
           assetImageRepository ??
           ImmichAssetImageRepository(dio: ImmichDioFactory.create()),
       _mediaRepository =
           mediaRepository ??
           ((useMockServices ?? false)
               ? MockMediaRepository()
               : ImmichMediaRepository(dio: ImmichDioFactory.create()));

  final AppEnvironment _environment;
  final AuthRepository _authRepository;
  final AssetImageRepository _assetImageRepository;
  final ServerRepository _serverRepository;
  final MediaRepository _mediaRepository;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.immichBlue,
        onPrimary: AppColors.darkTextPrimary,
        secondary: AppColors.immichPink,
        onSecondary: AppColors.darkTextPrimary,
        error: AppColors.immichRed,
        onError: AppColors.darkTextPrimary,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      canvasColor: AppColors.background,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppEnvironment>.value(value: _environment),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<AssetImageRepository>.value(
          value: _assetImageRepository,
        ),
        RepositoryProvider<ServerRepository>.value(value: _serverRepository),
        RepositoryProvider<MediaRepository>.value(value: _mediaRepository),
      ],
      child: MaterialApp(
        title: 'Immich TV',
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
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
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: const TextStyle(color: AppColors.textMuted),
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
              backgroundColor: AppColors.immichBlue,
              foregroundColor: AppColors.actionForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.immichBlue,
            linearTrackColor: AppColors.darkSurfaceSoft,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
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
