import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/asset_summary.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import 'cubit/asset_viewer_cubit.dart';

class AssetViewerScreen extends StatelessWidget {
  const AssetViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
    required this.accessToken,
  });

  final List<AssetSummary> assets;
  final int initialIndex;
  final String accessToken;

  static Future<void> show(
    BuildContext context, {
    required List<AssetSummary> assets,
    required int initialIndex,
    required String accessToken,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AssetViewerScreen(
              assets: assets,
              initialIndex: initialIndex,
              accessToken: accessToken,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AssetViewerCubit(assets: assets, initialIndex: initialIndex),
      child: _AssetViewerView(accessToken: accessToken),
    );
  }
}

class _AssetViewerView extends StatefulWidget {
  const _AssetViewerView({required this.accessToken});

  final String accessToken;

  @override
  State<_AssetViewerView> createState() => _AssetViewerViewState();
}

class _AssetViewerViewState extends State<_AssetViewerView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<AssetViewerCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetViewerCubit, AssetViewerState>(
      builder: (context, state) {
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousIntent(),
            SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _PreviousIntent: CallbackAction<_PreviousIntent>(
                onInvoke: (_) => _moveTo(state.currentIndex - 1),
              ),
              _NextIntent: CallbackAction<_NextIntent>(
                onInvoke: (_) => _moveTo(state.currentIndex + 1),
              ),
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => Navigator.of(context).maybePop(),
              ),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: state.assets.length,
                        onPageChanged: context.read<AssetViewerCubit>().jumpTo,
                        itemBuilder: (context, index) {
                          final asset = state.assets[index];
                          return _ViewerPage(
                            asset: asset,
                            accessToken: widget.accessToken,
                          );
                        },
                      ),
                      Positioned(
                        top: AppSpacing.lg,
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        child: _ViewerTopBar(
                          asset: state.currentAsset,
                          currentIndex: state.currentIndex,
                          itemCount: state.assets.length,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: AppSpacing.md,
                        child: _ViewerArrow(
                          icon: Icons.chevron_left,
                          enabled: state.hasPrevious,
                          onPressed: () => _moveTo(state.currentIndex - 1),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: AppSpacing.md,
                        child: _ViewerArrow(
                          icon: Icons.chevron_right,
                          enabled: state.hasNext,
                          onPressed: () => _moveTo(state.currentIndex + 1),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _moveTo(int index) {
    final cubit = context.read<AssetViewerCubit>();
    if (index < 0 || index >= cubit.state.assets.length) {
      return;
    }

    cubit.jumpTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({required this.asset, required this.accessToken});

  final AssetSummary asset;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    if (asset.isVideo) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF111A1E),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_display_outlined, size: 40),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Video playback lands next',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'This viewer is ready for photos today. The next playback slice will add a real fullscreen video experience on top of the same navigation shell.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: AuthenticatedAssetImage(
            imageUrls: asset.displayUrls,
            accessToken: accessToken,
            fit: BoxFit.contain,
            heroTag: 'asset-${asset.id}',
            placeholderIcon: Icons.photo_outlined,
          ),
        ),
      ),
    );
  }
}

class _ViewerTopBar extends StatelessWidget {
  const _ViewerTopBar({
    required this.asset,
    required this.currentIndex,
    required this.itemCount,
  });

  final AssetSummary asset;
  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1216),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.isVideo ? 'Video ${asset.id}' : 'Photo ${asset.id}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${asset.isVideo ? 'Video' : 'Photo'} • ${_formatDate(asset.createdAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${currentIndex + 1} / $itemCount',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _ViewerArrow extends StatelessWidget {
  const _ViewerArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.filledTonal(
        onPressed: enabled ? onPressed : null,
        iconSize: 42,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xB30C151A),
          disabledBackgroundColor: const Color(0x400C151A),
          minimumSize: const Size(64, 84),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _NextIntent extends Intent {
  const _NextIntent();
}
