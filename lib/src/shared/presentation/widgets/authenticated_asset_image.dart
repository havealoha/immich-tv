import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/network/immich_dio_factory.dart';
import '../../../core/network/immich_headers.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import 'loading_skeleton.dart';

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
    this.loadingPlaceholder,
  });

  final List<String> imageUrls;
  final String accessToken;
  final bool requiresAuth;
  final BoxFit fit;
  final String? heroTag;
  final double? borderRadius;
  final IconData placeholderIcon;
  final FilterQuality filterQuality;
  final Widget? loadingPlaceholder;

  @override
  State<AuthenticatedAssetImage> createState() =>
      _AuthenticatedAssetImageState();
}

class _AuthenticatedAssetImageState extends State<AuthenticatedAssetImage> {
  static final Dio _webImageDio = ImmichDioFactory.create();

  int _urlIndex = 0;
  bool _isAdvancingUrl = false;
  String? _webImageUrl;
  Future<Uint8List>? _webImageFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accessToken != widget.accessToken ||
        oldWidget.requiresAuth != widget.requiresAuth ||
        oldWidget.imageUrls.join('|') != widget.imageUrls.join('|')) {
      _resetImageState();
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

    if (widget.imageUrls.isEmpty) {
      return _wrapImage(
        _ImagePlaceholder(
          child: Icon(
            widget.placeholderIcon,
            color: AppColors.textMuted,
            size: 30,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final currentUrl = widget.imageUrls[_urlIndex];
        final targetSize = _resolveDecodeSize(context, constraints);

        if (kIsWeb && widget.requiresAuth) {
          return _buildWebAuthenticatedImage(
            currentUrl: currentUrl,
            targetSize: targetSize,
          );
        }

        return _wrapImage(
          Image.network(
            currentUrl,
            headers: widget.requiresAuth
                ? ImmichHeaders.mediaSessionToken(widget.accessToken)
                : null,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: widget.filterQuality,
            cacheWidth: targetSize.cacheWidth,
            cacheHeight: targetSize.cacheHeight,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }

              return _ImagePlaceholder(
                child:
                    widget.loadingPlaceholder ??
                    const LoadingSkeleton(showBorder: true),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              _advanceToNextUrl();
              return _ImagePlaceholder(
                child: Icon(
                  widget.placeholderIcon,
                  color: AppColors.textMuted,
                  size: 30,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWebAuthenticatedImage({
    required String currentUrl,
    required _DecodeTargetSize targetSize,
  }) {
    final future = _resolveWebImageFuture(currentUrl);

    return FutureBuilder<Uint8List>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _wrapImage(
            _ImagePlaceholder(
              child:
                  widget.loadingPlaceholder ??
                  const LoadingSkeleton(showBorder: true),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          _advanceToNextUrl();
          return _wrapImage(
            _ImagePlaceholder(
              child: Icon(
                widget.placeholderIcon,
                color: AppColors.textMuted,
                size: 30,
              ),
            ),
          );
        }

        return _wrapImage(
          Image.memory(
            snapshot.data!,
            fit: widget.fit,
            gaplessPlayback: true,
            filterQuality: widget.filterQuality,
            cacheWidth: targetSize.cacheWidth,
            cacheHeight: targetSize.cacheHeight,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }

              return _ImagePlaceholder(
                child:
                    widget.loadingPlaceholder ??
                    const LoadingSkeleton(showBorder: true),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              _advanceToNextUrl();
              return _ImagePlaceholder(
                child: Icon(
                  widget.placeholderIcon,
                  color: AppColors.textMuted,
                  size: 30,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _resetImageState() {
    _urlIndex = 0;
    _isAdvancingUrl = false;
    _webImageUrl = null;
    _webImageFuture = null;
  }

  void _advanceToNextUrl() {
    if (_isAdvancingUrl || _urlIndex >= widget.imageUrls.length - 1) {
      return;
    }

    _isAdvancingUrl = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _urlIndex += 1;
        _isAdvancingUrl = false;
        _webImageUrl = null;
        _webImageFuture = null;
      });
    });
  }

  Future<Uint8List> _resolveWebImageFuture(String currentUrl) {
    if (_webImageUrl == currentUrl && _webImageFuture != null) {
      return _webImageFuture!;
    }

    _webImageUrl = currentUrl;
    _webImageFuture = _fetchWebImageBytes(currentUrl);
    return _webImageFuture!;
  }

  Future<Uint8List> _fetchWebImageBytes(String url) async {
    final response = await _webImageDio.get<List<int>>(
      url,
      options: Options(
        headers: widget.requiresAuth
            ? ImmichHeaders.mediaSessionToken(widget.accessToken)
            : null,
        responseType: ResponseType.bytes,
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const FormatException('No image bytes returned.');
    }
    return Uint8List.fromList(data);
  }

  Widget _wrapImage(Widget child) {
    Widget current = child;

    if (widget.borderRadius != null) {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius!),
        child: current,
      );
    }

    if (widget.heroTag != null) {
      current = Hero(tag: widget.heroTag!, child: current);
    }

    return RepaintBoundary(child: current);
  }

  _DecodeTargetSize _resolveDecodeSize(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final devicePixelRatio = mediaQuery?.devicePixelRatio ?? 1.0;
    final decodeScaleCap = widget.fit == BoxFit.contain ? 2.0 : 1.2;
    final effectivePixelRatio = devicePixelRatio.clamp(1.0, decodeScaleCap);

    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : mediaQuery?.size.width ?? 0;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : mediaQuery?.size.height ?? 0;

    final scaledWidth = _scaledDimension(width, effectivePixelRatio);
    final scaledHeight = _scaledDimension(height, effectivePixelRatio);

    if (scaledWidth == null && scaledHeight == null) {
      return const _DecodeTargetSize();
    }

    if (scaledWidth == null) {
      return _DecodeTargetSize(cacheHeight: scaledHeight);
    }

    if (scaledHeight == null) {
      return _DecodeTargetSize(cacheWidth: scaledWidth);
    }

    return scaledWidth >= scaledHeight
        ? _DecodeTargetSize(cacheWidth: scaledWidth)
        : _DecodeTargetSize(cacheHeight: scaledHeight);
  }

  int? _scaledDimension(double logicalDimension, double pixelRatio) {
    if (logicalDimension <= 0 || !logicalDimension.isFinite) {
      return null;
    }

    return (logicalDimension * pixelRatio).round().clamp(64, 4096);
  }
}

class _DecodeTargetSize {
  const _DecodeTargetSize({this.cacheWidth, this.cacheHeight});

  final int? cacheWidth;
  final int? cacheHeight;
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020202), Color(0xFF090909)],
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
