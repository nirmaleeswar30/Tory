import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

class SourceChip extends StatelessWidget {
  final String source;
  final bool isSelected;
  final VoidCallback onTap;

  const SourceChip({
    super.key,
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = AppConstants.sourceDisplayNames[source] ?? source;
    final emoji = AppConstants.sourceEmojis[source] ?? '📦';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.crimson.withValues(alpha: 0.2)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.crimson
                : AppTheme.textMuted.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: TextStyle(
                color: isSelected ? AppTheme.crimson : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
