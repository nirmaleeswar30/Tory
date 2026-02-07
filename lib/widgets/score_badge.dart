import 'package:flutter/material.dart';

import '../core/theme.dart';

class ScoreBadge extends StatelessWidget {
  final double score;
  final double size;

  const ScoreBadge({super.key, required this.score, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          score.round().toString(),
          style: TextStyle(
            color: color,
            fontSize: size * 0.36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
