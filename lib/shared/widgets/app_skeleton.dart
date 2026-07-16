import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final shimmer = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = _controller.value * 2.6 - 1.3;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(offset - 0.3, 0.0),
              end: Alignment(offset + 0.3, 0.0),
              colors: [base, shimmer, base],
            ),
          ),
        );
      },
    );
  }
}

class AppSkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class AppSkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsets margin;

  const AppSkeletonCard({
    super.key,
    this.height = 120,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: AppSkeleton(
        width: double.infinity,
        height: height,
        borderRadius: 14,
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  final int itemCount;

  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < itemCount - 1 ? 12 : 0),
          child: AppSkeletonLine(
            height: 14,
            width: i.isEven ? 1.0 : 0.7,
          ),
        ),
      ),
    );
  }
}
