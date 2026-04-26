import 'package:flutter/material.dart';

/// A shimmer-effect skeleton loading widget for content placeholders
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 10,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFEBEDF1),
                Color(0xFFF5F6F8),
                Color(0xFFEBEDF1),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton card for ride list loading
class RideCardSkeleton extends StatelessWidget {
  const RideCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(width: 44, height: 44, borderRadius: 22),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 120, height: 16),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 80, height: 12),
                  ],
                ),
              ),
              SkeletonLoader(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              SkeletonLoader(width: 10, height: 10, borderRadius: 5),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 14)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              SkeletonLoader(width: 10, height: 10, borderRadius: 5),
              SizedBox(width: 10),
              Expanded(child: SkeletonLoader(height: 14)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 32, borderRadius: 16)),
              SizedBox(width: 12),
              SkeletonLoader(width: 80, height: 32, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }
}
