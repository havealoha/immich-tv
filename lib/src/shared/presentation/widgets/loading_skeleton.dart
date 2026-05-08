import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.baseColor = const Color(0xFF050505),
    this.highlightColor = const Color(0xFF171717),
    this.showBorder = false,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final bool showBorder;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.showBorder
                  ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                  : null,
              gradient: LinearGradient(
                begin: Alignment(-1.9 + (value * 3.2), -0.35),
                end: Alignment(-0.7 + (value * 3.2), 0.35),
                colors: [
                  widget.baseColor,
                  Color.lerp(widget.baseColor, Colors.white, 0.12)!,
                  widget.highlightColor,
                  Color.lerp(widget.highlightColor, Colors.white, 0.16)!,
                  widget.baseColor,
                ],
                stops: const [0.08, 0.28, 0.52, 0.72, 0.94],
              ),
            ),
          );
        },
      ),
    );
  }
}
