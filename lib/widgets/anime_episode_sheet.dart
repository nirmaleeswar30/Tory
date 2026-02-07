import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/anilist_media.dart';
import '../screens/anime_episode_screen.dart';

/// Shows a bottom sheet for an AniList anime, matching the TMDB season picker
/// style. Returns the chosen search query or null.
Future<String?> showAnimeEpisodeSheet(
  BuildContext context, {
  required AnilistMedia anime,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _AnimePickerSheet(anime: anime),
  );
}

// ── Episode range (analogous to TMDB "season") ──────────────────────

class _EpisodeRange {
  final int start;
  final int end;

  _EpisodeRange({required this.start, required this.end});

  int get count => end - start + 1;

  String get label =>
      start == end ? 'Episode $start' : 'Episodes $start – $end';
}

// ── Picker sheet ─────────────────────────────────────────────────────

class _AnimePickerSheet extends StatelessWidget {
  final AnilistMedia anime;

  const _AnimePickerSheet({required this.anime});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final totalEps = anime.episodes ?? 0;
    final airedEps = anime.nextAiringEpisode != null
        ? anime.nextAiringEpisode! - 1
        : 0;
    final epCount = totalEps > 0 ? totalEps : airedEps;

    // Build episode ranges (chunked like TMDB seasons)
    final ranges = <_EpisodeRange>[];
    if (epCount > 0) {
      const chunkSize = 25;
      if (epCount <= chunkSize) {
        ranges.add(_EpisodeRange(start: 1, end: epCount));
      } else {
        for (var i = 1; i <= epCount; i += chunkSize) {
          final end = (i + chunkSize - 1).clamp(1, epCount);
          ranges.add(_EpisodeRange(start: i, end: end));
        }
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header with banner ───────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: anime.bannerImage != null
                  ? DecorationImage(
                      image: NetworkImage(anime.bannerImage!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.4),
                        BlendMode.darken,
                      ),
                    )
                  : anime.posterUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(anime.posterUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.5),
                        BlendMode.darken,
                      ),
                    )
                  : null,
              color: AppTheme.deepNavy,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.cardDark.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.displayTitle,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (ranges.length > 1)
                            '${ranges.length} parts'
                          else if (epCount > 0)
                            '$epCount episodes',
                          if (anime.year.isNotEmpty) anime.year,
                          if (anime.status == 'RELEASING') 'Airing',
                        ].join('  •  '),
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Search full anime button ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: AppTheme.crimson.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, anime.searchQuery),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppTheme.crimson.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Search full anime',
                        style: TextStyle(
                          color: AppTheme.crimson,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Episode range list (like season cards) ───────────
          if (ranges.isNotEmpty)
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
                shrinkWrap: true,
                itemCount: ranges.length,
                itemBuilder: (context, index) {
                  final range = ranges[index];
                  return _RangeCard(
                    range: range,
                    anime: anime,
                    onTap: () async {
                      final query = await Navigator.of(context).push<String>(
                        PageRouteBuilder(
                          pageBuilder: (ctx, anim, secAnim) =>
                              AnimeEpisodeScreen(
                                anime: anime,
                                startEp: range.start,
                                endEp: range.end,
                              ),
                          transitionsBuilder: (ctx, anim, secAnim, child) {
                            return SlideTransition(
                              position:
                                  Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 280),
                        ),
                      );
                      if (query != null && context.mounted) {
                        Navigator.pop(context, query);
                      }
                    },
                    onSearchRange: () {
                      final title = anime.searchQuery;
                      if (range.start == 1 && range.end == epCount) {
                        Navigator.pop(context, title);
                      } else {
                        final s = anime.seasonNumber.toString().padLeft(2, '0');
                        Navigator.pop(context, '$title S$s');
                      }
                    },
                  );
                },
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
              child: Text(
                'Episode count unknown — use "Search full anime" above',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Range card (matches TMDB season card style) ──────────────────────

class _RangeCard extends StatelessWidget {
  final _EpisodeRange range;
  final AnilistMedia anime;
  final VoidCallback onTap;
  final VoidCallback onSearchRange;

  const _RangeCard({
    required this.range,
    required this.anime,
    required this.onTap,
    required this.onSearchRange,
  });

  @override
  Widget build(BuildContext context) {
    final hasAiring =
        anime.status == 'RELEASING' &&
        anime.nextAiringEpisode != null &&
        anime.nextAiringEpisode! >= range.start &&
        anime.nextAiringEpisode! <= range.end;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.deepNavy.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Poster thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50,
                    height: 70,
                    child: anime.posterUrl.isNotEmpty
                        ? Image.network(
                            anime.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(range.start, range.end),
                          )
                        : _placeholder(range.start, range.end),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        range.label,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _pill('${range.count} eps'),
                          if (hasAiring) ...[
                            const SizedBox(width: 6),
                            _pill(
                              'AIRING',
                              color: AppTheme.crimson.withValues(alpha: 0.15),
                              textColor: AppTheme.crimson,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onSearchRange,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.crimson.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.crimson,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _placeholder(int start, int end) {
    return Container(
      color: AppTheme.darkSurface,
      child: Center(
        child: Text(
          start == end ? '$start' : '$start-\n$end',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.crimson,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  static Widget _pill(String text, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
