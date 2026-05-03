import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_environment.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';

class BootstrapFlow extends StatefulWidget {
  const BootstrapFlow({super.key});

  @override
  State<BootstrapFlow> createState() => _BootstrapFlowState();
}

class _BootstrapFlowState extends State<BootstrapFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowPulse;
  late final Animation<double> _panelRise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(
      begin: 0.78,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _panelRise = Tween<double>(
      begin: 16,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useMockServices = context.read<AppEnvironment>().useMockServices;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFF1C4B59),
                  Color(0xFF102732),
                  Color(0xFF08131A),
                ],
                center: Alignment(-0.3, -0.7),
                radius: 1.25,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -80,
                  right: -40,
                  child: Opacity(
                    opacity: 0.14 * _glowPulse.value,
                    child: _GlowOrb(size: 260, color: const Color(0xFFB5FFF6)),
                  ),
                ),
                Positioned(
                  bottom: -110,
                  left: -60,
                  child: Opacity(
                    opacity: 0.12 * _glowPulse.value,
                    child: _GlowOrb(size: 320, color: const Color(0xFF5ACCC5)),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, _panelRise.value),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Container(
                          margin: const EdgeInsets.all(AppSpacing.lg),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                            vertical: AppSpacing.xl,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xB30B171D),
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6FE0DB,
                                ).withValues(alpha: 0.12 * _glowPulse.value),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BrandMark(glowPulse: _glowPulse.value),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'ImmichTV',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                useMockServices
                                    ? 'Loading the mock-first living room showcase'
                                    : 'Preparing your living room photo experience',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  _SplashChip(
                                    icon: Icons.tv_rounded,
                                    label: 'TV-first',
                                  ),
                                  _SplashChip(
                                    icon: Icons.photo_library_outlined,
                                    label: 'Timeline ready',
                                  ),
                                  _SplashChip(
                                    icon: useMockServices
                                        ? Icons.auto_awesome_outlined
                                        : Icons.cloud_done_outlined,
                                    label: useMockServices
                                        ? 'Demo mode'
                                        : 'Live services',
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFF16333E),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.lerp(
                                          const Color(0xFF6FE0DB),
                                          Colors.white,
                                          1 - _glowPulse.value,
                                        ) ??
                                        AppColors.focus,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                useMockServices
                                    ? 'Bootstrapping polished mock content, navigation, and viewer flows.'
                                    : 'Restoring your session and preparing the gallery shell.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.glowPulse});

  final double glowPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF85FFF1), Color(0xFF3DA39E), Color(0xFF163F4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6FE0DB).withValues(alpha: 0.26 * glowPulse),
            blurRadius: 36,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xCC0A171D),
            ),
          ),
          const Icon(
            Icons.connected_tv_rounded,
            size: 42,
            color: Color(0xFFF0FFFD),
          ),
        ],
      ),
    );
  }
}

class _SplashChip extends StatelessWidget {
  const _SplashChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: const Color(0x61122128),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.focus),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
