import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/torrent.dart';
import 'score_badge.dart';

class TorrentCard extends StatelessWidget {
  final Torrent torrent;
  final VoidCallback onTap;
  final int index;

  const TorrentCard({
    super.key,
    required this.torrent,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final sourceEmoji = AppConstants.sourceEmojis[torrent.source] ?? '📦';
    final sourceName =
        AppConstants.sourceDisplayNames[torrent.source] ?? torrent.source;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScoreBadge(score: torrent.qualityScore),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    torrent.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Source + Size tags
                  Row(
                    children: [
                      _tag('$sourceEmoji $sourceName', const Color(0xFF5DADE2)),
                      if (torrent.size.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _tag(torrent.size, AppTheme.crimson),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 14,
                        color: AppTheme.seeders,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        torrent.formattedSeeders,
                        style: const TextStyle(
                          color: AppTheme.seeders,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppTheme.leechers,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        torrent.formattedLeechers,
                        style: const TextStyle(
                          color: AppTheme.leechers,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (torrent.downloads > 0) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.download_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          torrent.formattedDownloads,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (torrent.dateUploaded != null)
                        Flexible(
                          child: Text(
                            torrent.dateUploaded!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
