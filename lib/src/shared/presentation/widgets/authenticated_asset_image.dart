import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/asset_image_repository.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

class AuthenticatedAssetImage extends StatefulWidget {
  const AuthenticatedAssetImage({
    super.key,
    required this.imageUrls,
    required this.accessToken,
    this.requiresAuth = true,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
    this.filterQuality = FilterQuality.low,
  });

  final List<String> imageUrls;
  final String accessToken;
  final bool requiresAuth;
  final BoxFit fit;
  final String? heroTag;
  final double? borderRadius;
  final IconData placeholderIcon;
  final FilterQuality filterQuality;

  @override
  State<AuthenticatedAssetImage> createState() =>
      _AuthenticatedAssetImageState();
}

class _AuthenticatedAssetImageState extends State<AuthenticatedAssetImage> {
  Future<Uint8List>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _syncFuture();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accessToken != widget.accessToken ||
        oldWidget.requiresAuth != widget.requiresAuth ||
        oldWidget.imageUrls.join('|') != widget.imageUrls.join('|')) {
      _syncFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryUrl = widget.imageUrls.isNotEmpty
        ? widget.imageUrls.first
        : null;
    if (primaryUrl != null && primaryUrl.startsWith('mock://')) {
      Widget child = _MockAssetArt(imageUrl: primaryUrl, fit: widget.fit);
      if (widget.borderRadius != null) {
        child = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius!),
          child: child,
        );
      }

      if (widget.heroTag != null) {
        child = Hero(tag: widget.heroTag!, child: child);
      }

      return child;
    }

    if (!widget.requiresAuth && primaryUrl != null) {
      Widget child = Image.network(
        primaryUrl,
        fit: widget.fit,
        filterQuality: widget.filterQuality,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) {
            return widget;
          }

          return const _ImagePlaceholder(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ImagePlaceholder(
            child: Icon(
              widget.placeholderIcon,
              color: AppColors.textMuted,
              size: 30,
            ),
          );
        },
      );

      if (widget.borderRadius != null) {
        child = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius!),
          child: child,
        );
      }

      if (widget.heroTag != null) {
        child = Hero(tag: widget.heroTag!, child: child);
      }

      return child;
    }

    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const _ImagePlaceholder(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          child = _ImagePlaceholder(
            child: Icon(
              widget.placeholderIcon,
              color: AppColors.textMuted,
              size: 30,
            ),
          );
        } else {
          child = Image.memory(
            snapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: widget.filterQuality,
          );
        }

        if (widget.borderRadius != null) {
          child = ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius!),
            child: child,
          );
        }

        if (widget.heroTag != null) {
          child = Hero(tag: widget.heroTag!, child: child);
        }

        return RepaintBoundary(child: child);
      },
    );
  }

  void _syncFuture() {
    if (!widget.requiresAuth) {
      _imageFuture = null;
      return;
    }

    _imageFuture = context.read<AssetImageRepository>().fetchImageBytes(
      urls: widget.imageUrls,
      accessToken: widget.accessToken,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF17303A), Color(0xFF10232A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _MockAssetArt extends StatelessWidget {
  const _MockAssetArt({required this.imageUrl, required this.fit});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(imageUrl);
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'asset';
    final palette = uri.queryParameters['palette'] ?? 'sea-glass';
    final variant = uri.queryParameters['variant'] ?? 'thumbnail';
    final colors = _paletteColors(palette);
    final isDisplay = variant == 'display';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: isDisplay ? -40 : -20,
            right: isDisplay ? -10 : -20,
            child: Container(
              width: isDisplay ? 220 : 120,
              height: isDisplay ? 220 : 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x26FFFFFF),
              ),
            ),
          ),
          Positioned(
            bottom: isDisplay ? -50 : -24,
            left: isDisplay ? -20 : -30,
            child: Container(
              width: isDisplay ? 260 : 140,
              height: isDisplay ? 260 : 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFFFFFF),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDisplay ? AppSpacing.xxl : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    palette.replaceAll('-', ' ').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.photo_camera_back_outlined,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: isDisplay ? 56 : 28,
                ),
                SizedBox(height: isDisplay ? AppSpacing.lg : AppSpacing.sm),
                Text(
                  'Scene ${id.split('-').last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (isDisplay
                              ? Theme.of(context).textTheme.headlineLarge
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                ),
                SizedBox(height: isDisplay ? AppSpacing.sm : AppSpacing.xxs),
                Text(
                  fit == BoxFit.contain
                      ? 'Curated mock photo for fullscreen TV preview'
                      : 'Curated mock photo',
                  maxLines: isDisplay ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _paletteColors(String palette) {
    return switch (palette) {
      'sunrise' => const [
        Color(0xFFF48C6A),
        Color(0xFFF5C96B),
        Color(0xFFF7E7B1),
      ],
      'dusk' => const [Color(0xFF1F3B73), Color(0xFF4967A8), Color(0xFF8FA7E6)],
      'citrus' => const [
        Color(0xFFF97316),
        Color(0xFFFACC15),
        Color(0xFFFDE68A),
      ],
      'ember' => const [
        Color(0xFF7F1D1D),
        Color(0xFFB91C1C),
        Color(0xFFFCA5A5),
      ],
      'forest' => const [
        Color(0xFF0F766E),
        Color(0xFF15803D),
        Color(0xFF86EFAC),
      ],
      _ => const [Color(0xFF134E5E), Color(0xFF2B7A78), Color(0xFF8FE3CF)],
    };
  }
}
