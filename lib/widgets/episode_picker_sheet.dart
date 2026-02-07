import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../models/tmdb_media.dart';
import '../screens/episode_screen.dart';

// ── Data classes ─────────────────────────────────────────────────────

class SeasonInfo {
  final int number;
  final String name;
  final int episodeCount;
  final String airDate;
  final String? posterPath;

  SeasonInfo({
    required this.number,
    required this.name,
    required this.episodeCount,
    required this.airDate,
    this.posterPath,
  });

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';
}

/// Shows a bottom sheet with season list. Tapping a season opens a full-screen
/// episode browser. Returns the search query string or null.
Future<String?> showEpisodePickerSheet(
  BuildContext context, {
  required TmdbMedia media,
  required String tmdbApiKey,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SeasonPickerSheet(media: media, tmdbApiKey: tmdbApiKey),
  );
}

class _SeasonPickerSheet extends StatefulWidget {
  final TmdbMedia media;
  final String tmdbApiKey;

  const _SeasonPickerSheet({required this.media, required this.tmdbApiKey});

  @override
  State<_SeasonPickerSheet> createState() => _SeasonPickerSheetState();
}

class _SeasonPickerSheetState extends State<_SeasonPickerSheet> {
  List<SeasonInfo> _seasons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSeasons();
  }

  Future<void> _fetchSeasons() async {
    try {
      final url =
          'https://api.themoviedb.org/3/tv/${widget.media.id}?api_key=${widget.tmdbApiKey}';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['seasons'] as List? ?? [];
        final parsed = list
            .map(
              (s) => SeasonInfo(
                number: s['season_number'] as int? ?? 0,
                name: s['name'] as String? ?? 'Season',
                episodeCount: s['episode_count'] as int? ?? 0,
                airDate: s['air_date'] as String? ?? '',
                posterPath: s['poster_path'] as String?,
              ),
            )
            .where((s) => s.episodeCount > 0)
            .toList();
        if (mounted)
          setState(() {
            _seasons = parsed;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
            _error = 'Failed to load';
            _loading = false;
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Network error';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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
          // ── Drag handle
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

          // ── Header with backdrop
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: widget.media.backdropUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.media.backdropUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.4),
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
                        widget.media.title,
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
                        _loading
                            ? widget.media.year
                            : '${_seasons.length} seasons  •  ${widget.media.year}',
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

          // ── Search full show button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: AppTheme.crimson.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, widget.media.searchQuery),
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
                        'Search full show',
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

          // ── Season list
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.crimson,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
                    shrinkWrap: true,
                    itemCount: _seasons.length,
                    itemBuilder: (context, index) {
                      final season = _seasons[index];
                      return _SeasonCard(
                        season: season,
                        onTap: () async {
                          final query = await Navigator.of(context)
                              .push<String>(
                                PageRouteBuilder(
                                  pageBuilder: (ctx, anim, secAnim) =>
                                      EpisodeScreen(
                                        media: widget.media,
                                        season: season,
                                        tmdbApiKey: widget.tmdbApiKey,
                                      ),
                                  transitionsBuilder:
                                      (ctx, anim, secAnim, child) {
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
                                  transitionDuration: const Duration(
                                    milliseconds: 280,
                                  ),
                                ),
                              );
                          if (query != null && context.mounted) {
                            Navigator.pop(context, query);
                          }
                        },
                        onSearchSeason: () {
                          final title = widget.media.title;
                          final s = season.number.toString().padLeft(2, '0');
                          Navigator.pop(context, '$title Season $s');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Season card widget ───────────────────────────────────────────────

class _SeasonCard extends StatelessWidget {
  final SeasonInfo season;
  final VoidCallback onTap;
  final VoidCallback onSearchSeason;

  const _SeasonCard({
    required this.season,
    required this.onTap,
    required this.onSearchSeason,
  });

  @override
  Widget build(BuildContext context) {
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
                // Season poster thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50,
                    height: 70,
                    child: season.posterUrl.isNotEmpty
                        ? Image.network(
                            season.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(season.number),
                          )
                        : _placeholder(season.number),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _pill('${season.episodeCount} eps'),
                          if (season.airDate.length >= 4) ...[
                            const SizedBox(width: 6),
                            _pill(season.airDate.substring(0, 4)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onSearchSeason,
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

  static Widget _placeholder(int number) {
    return Container(
      color: AppTheme.darkSurface,
      child: Center(
        child: Text(
          'S$number',
          style: const TextStyle(
            color: AppTheme.crimson,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  static Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
