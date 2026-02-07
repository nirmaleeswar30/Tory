import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Skeleton placeholder shown while search results are loading.
class ShimmerLoader extends StatefulWidget {
  final int itemCount;

  const ShimmerLoader({super.key, this.itemCount = 6});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShimmerCard(progress: _controller.value),
            );
          },
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double progress;

  const _ShimmerCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _circle(44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(double.infinity, 14),
                const SizedBox(height: 10),
                _box(180, 12),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _box(60, 10),
                    const SizedBox(width: 12),
                    _box(60, 10),
                    const SizedBox(width: 12),
                    _box(40, 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * progress, 0),
          end: Alignment(-1.0 + 2.0 * progress + 1, 0),
          colors: [
            AppTheme.cardLight.withValues(alpha: 0.3),
            AppTheme.cardLight.withValues(alpha: 0.6),
            AppTheme.cardLight.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * progress, 0),
          end: Alignment(-1.0 + 2.0 * progress + 1, 0),
          colors: [
            AppTheme.cardLight.withValues(alpha: 0.3),
            AppTheme.cardLight.withValues(alpha: 0.6),
            AppTheme.cardLight.withValues(alpha: 0.3),
          ],
        ),
      ),
    );
  }
}
