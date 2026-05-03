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
import 'src/features/library/data/noop_media_repository.dart';
import 'src/features/onboarding/data/immich_server_repository.dart';
import 'src/platform/storage/platform_session_storage.dart';

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
       _mediaRepository = mediaRepository ?? NoopMediaRepository();

  final AuthRepository _authRepository;
  final ServerRepository _serverRepository;
  final MediaRepository _mediaRepository;

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E847F),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF08131A),
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
            color: const Color(0xFF10232D),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF1E3947)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF0F2029),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF2A4656)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF2A4656)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF6FE0DB), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFFB6D6D4)),
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
