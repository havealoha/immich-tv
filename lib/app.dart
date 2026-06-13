import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/app_shell.dart';
import 'src/core/config/app_environment.dart';
import 'src/core/network/immich_dio_factory.dart';
import 'src/core/repositories/asset_image_repository.dart';
import 'src/core/repositories/auth_repository.dart';
import 'src/core/repositories/media_repository.dart';
import 'src/core/repositories/server_repository.dart';
import 'src/core/services/server_url_normalizer.dart';
import 'src/features/app_flow/cubit/app_flow_cubit.dart';
import 'src/features/auth/data/immich_auth_repository.dart';
import 'src/features/library/data/immich_asset_image_repository.dart';
import 'src/features/library/data/immich_media_repository.dart';
import 'src/features/marketing/marketing_landing_screen.dart';
import 'src/features/mock/data/mock_auth_repository.dart';
import 'src/features/mock/data/mock_media_repository.dart';
import 'src/features/mock/data/mock_server_repository.dart';
import 'src/features/onboarding/data/immich_server_repository.dart';
import 'src/features/remote_input/remote_text_input_page.dart';
import 'src/platform/browser_navigation.dart';
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
           assetImageRepository ?? ImmichAssetImageRepository(),
       _mediaRepository =
           mediaRepository ??
           ((useMockServices ?? false)
               ? MockMediaRepository()
               : ImmichMediaRepository(dio: ImmichDioFactory.create()));

  final AppEnvironment _environment;
  late final AuthRepository _authRepository;
  late final AssetImageRepository _assetImageRepository;
  late final ServerRepository _serverRepository;
  late final MediaRepository _mediaRepository;

  @override
  Widget build(BuildContext context) {
    final appRepositories = <RepositoryProvider>[
      RepositoryProvider<AppEnvironment>.value(value: _environment),
      RepositoryProvider<AuthRepository>.value(value: _authRepository),
      RepositoryProvider<AssetImageRepository>.value(
        value: _assetImageRepository,
      ),
      RepositoryProvider<ServerRepository>.value(value: _serverRepository),
      RepositoryProvider<MediaRepository>.value(value: _mediaRepository),
    ];

    final remoteInputSessionId = _remoteInputSessionId;
    if (remoteInputSessionId != null) {
      return _MarketingSiteApp(
        repositories: appRepositories,
        appHome: _AdaptiveAppEntry(authRepository: _authRepository),
        homeOverride: RemoteTextInputPage(sessionId: remoteInputSessionId),
      );
    }

    if (_shouldShowMarketingLanding) {
      return _MarketingSiteApp(
        repositories: appRepositories,
        appHome: _AdaptiveAppEntry(authRepository: _authRepository),
      );
    }

    final baseTextTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.0,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.02,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.05,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.45,
        height: 1.08,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.08,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.1,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.12,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.18,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
        height: 1.2,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.2,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.2,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        height: 1.2,
      ),
    );

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
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
    );

    return MultiRepositoryProvider(
      providers: appRepositories,
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
        home: _AdaptiveAppEntry(authRepository: _authRepository),
      ),
    );
  }

  bool get _shouldShowMarketingLanding {
    if (!kIsWeb) {
      return false;
    }

    final normalizedPath = Uri.base.path.toLowerCase();
    return normalizedPath.isEmpty ||
        normalizedPath == '/' ||
        normalizedPath == '/index.html';
  }

  String? get _remoteInputSessionId {
    if (!kIsWeb) {
      return null;
    }

    final segments = Uri.base.pathSegments;
    if (segments.length == 2 && segments.first.toLowerCase() == 'input') {
      return segments.last;
    }
    return null;
  }
}

class _AdaptiveAppEntry extends StatelessWidget {
  const _AdaptiveAppEntry({required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return _AdaptiveViewportGate(authRepository: authRepository);
  }
}

class _AdaptiveViewportGate extends StatefulWidget {
  const _AdaptiveViewportGate({required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<_AdaptiveViewportGate> createState() => _AdaptiveViewportGateState();
}

class _AdaptiveViewportGateState extends State<_AdaptiveViewportGate> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppFlowCubit(widget.authRepository)..initialize(),
      child: const AppShell(),
    );
  }
}

class _MarketingSiteApp extends StatelessWidget {
  const _MarketingSiteApp({
    required this.repositories,
    required this.appHome,
    this.homeOverride,
  });

  final List<RepositoryProvider> repositories;
  final Widget appHome;
  final Widget? homeOverride;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: repositories,
      child: MaterialApp(
        title: 'Immich TV',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.immichBlue,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: homeOverride ?? _MarketingSiteGate(appHome: appHome),
      ),
    );
  }
}

class _MarketingSiteGate extends StatefulWidget {
  const _MarketingSiteGate({required this.appHome});

  final Widget appHome;

  @override
  State<_MarketingSiteGate> createState() => _MarketingSiteGateState();
}

class _MarketingSiteGateState extends State<_MarketingSiteGate> {
  bool _showWebApp = false;

  @override
  Widget build(BuildContext context) {
    if (_showWebApp) {
      return widget.appHome;
    }

    return MarketingLandingScreen(
      onOpenWebApp: () {
        pushBrowserPath('/app');
        setState(() => _showWebApp = true);
      },
    );
  }
}
