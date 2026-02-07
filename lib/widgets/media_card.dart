import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/tmdb_media.dart';

class MediaCard extends StatelessWidget {
  final TmdbMedia media;
  final VoidCallback onTap;

  const MediaCard({super.key, required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster ──
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  media.posterUrl.isNotEmpty
                      ? Image.network(
                          media.posterUrl,
                          width: 130,
                          height: 195,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  // Rating badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Color(0xFFF39C12),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            media.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Media type badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: media.mediaType == 'movie'
                            ? AppTheme.crimson.withValues(alpha: 0.9)
                            : AppTheme.purple.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        media.mediaType == 'movie' ? 'MOVIE' : 'TV',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Title ──
            Text(
              media.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            // ── Year ──
            if (media.year.isNotEmpty)
              Text(
                media.year,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 130,
      height: 195,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.movie_rounded,
        color: AppTheme.textMuted,
        size: 36,
      ),
    );
  }
}
