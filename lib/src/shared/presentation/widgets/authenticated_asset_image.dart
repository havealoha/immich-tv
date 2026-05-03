import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/asset_image_repository.dart';
import '../app_colors.dart';

class AuthenticatedAssetImage extends StatelessWidget {
  const AuthenticatedAssetImage({
    super.key,
    required this.imageUrls,
    required this.accessToken,
    this.fit = BoxFit.cover,
    this.heroTag,
    this.borderRadius,
    this.placeholderIcon = Icons.image_outlined,
  });

  final List<String> imageUrls;
  final String accessToken;
  final BoxFit fit;
  final String? heroTag;
  final double? borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final future = context.read<AssetImageRepository>().fetchImageBytes(
      urls: imageUrls,
      accessToken: accessToken,
    );

    return FutureBuilder<Uint8List>(
      future: future,
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
            child: Icon(placeholderIcon, color: AppColors.textMuted, size: 30),
          );
        } else {
          child = Image.memory(
            snapshot.data!,
            fit: fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          );
        }

        if (borderRadius != null) {
          child = ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius!),
            child: child,
          );
        }

        if (heroTag != null) {
          child = Hero(tag: heroTag!, child: child);
        }

        return child;
      },
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
