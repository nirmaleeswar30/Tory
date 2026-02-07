import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../models/anilist_media.dart';

// ── Jikan episode data ───────────────────────────────────────────────

class _JikanEpisode {
  final int number;
  final String title;
  final String? aired;
  final double score;
  final bool filler;
  final bool recap;

  _JikanEpisode({
    required this.number,
    required this.title,
    this.aired,
    this.score = 0,
    this.filler = false,
    this.recap = false,
  });

  factory _JikanEpisode.fromJson(Map<String, dynamic> json) {
    return _JikanEpisode(
      number: json['mal_id'] as int? ?? 0,
      title: (json['title'] ?? '') as String,
      aired: json['aired'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      filler: json['filler'] as bool? ?? false,
      recap: json['recap'] as bool? ?? false,
    );
  }

  String get airDateShort {
    if (aired == null || aired!.isEmpty) return '';
    try {
      final dt = DateTime.parse(aired!);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return aired!.length >= 10 ? aired!.substring(0, 10) : aired!;
    }
  }
}

/// Full-screen episode browser for anime, matching the TMDB EpisodeScreen style.
/// Fetches episode data (titles, air dates, scores) from the Jikan API
/// and uses the anime poster as thumbnails.
class AnimeEpisodeScreen extends StatefulWidget {
  final AnilistMedia anime;
  final int startEp;
  final int endEp;

  const AnimeEpisodeScreen({
    super.key,
    required this.anime,
    required this.startEp,
    required this.endEp,
  });

  @override
  State<AnimeEpisodeScreen> createState() => _AnimeEpisodeScreenState();
}

class _AnimeEpisodeScreenState extends State<AnimeEpisodeScreen> {
  Map<int, _JikanEpisode> _episodes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes() async {
    final malId = widget.anime.idMal;
    if (malId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      // Jikan paginates 100 eps per page
      final Map<int, _JikanEpisode> all = {};
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final url = 'https://api.jikan.moe/v4/anime/$malId/episodes?page=$page';
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = data['data'] as List? ?? [];
          for (final e in list) {
            final ep = _JikanEpisode.fromJson(e as Map<String, dynamic>);
            if (ep.number >= widget.startEp && ep.number <= widget.endEp) {
              all[ep.number] = ep;
            }
          }
          final pagination = data['pagination'] as Map<String, dynamic>?;
          hasMore = pagination?['has_next_page'] == true;
          // Stop if we've passed our range
          if (list.isNotEmpty) {
            final lastNum =
                (list.last as Map<String, dynamic>)['mal_id'] as int? ?? 0;
            if (lastNum >= widget.endEp) hasMore = false;
          }
          page++;
          // Brief delay to respect Jikan rate limits
          if (hasMore) {
            await Future.delayed(const Duration(milliseconds: 350));
          }
        } else {
          hasMore = false;
        }
      }

      if (mounted)
        setState(() {
          _episodes = all;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildQuery(int episode) {
    final title = widget.anime.searchQuery;
    final s = widget.anime.seasonNumber.toString().padLeft(2, '0');
    final e = episode.toString().padLeft(2, '0');
    return '$title S${s}E$e';
  }

  String _buildRangeQuery() {
    final title = widget.anime.searchQuery;
    if (widget.startEp == 1 &&
        widget.endEp == (widget.anime.episodes ?? widget.endEp)) {
      return title;
    }
    final s = widget.anime.seasonNumber.toString().padLeft(2, '0');
    return '$title S$s';
  }

  @override
  Widget build(BuildContext context) {
    final nextAiringEp = widget.anime.nextAiringEpisode;

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing app bar with banner ───────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.deepNavy,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner / poster fallback
                  if (widget.anime.bannerImage != null)
                    Image.network(
                      widget.anime.bannerImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.cardDark),
                    )
                  else if (widget.anime.posterUrl.isNotEmpty)
                    Image.network(
                      widget.anime.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.cardDark),
                    )
                  else
                    Container(color: AppTheme.cardDark),
                  // Dark gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.deepNavy.withValues(alpha: 0.7),
                          AppTheme.deepNavy,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Show + range info
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.anime.displayTitle,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.crimson,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.startEp == widget.endEp
                                    ? 'Episode ${widget.startEp}'
                                    : 'EP ${widget.startEp} – ${widget.endEp}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${widget.endEp - widget.startEp + 1} episodes',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            if (widget.anime.year.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•  ${widget.anime.year}',
                                style: TextStyle(
                                  color: AppTheme.textMuted.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search range button ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Material(
                color: AppTheme.crimson.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, _buildRangeQuery()),
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
                        Text(
                          widget.startEp == 1 &&
                                  widget.endEp ==
                                      (widget.anime.episodes ?? widget.endEp)
                              ? 'Search all episodes'
                              : 'Search Episodes ${widget.startEp} – ${widget.endEp}',
                          style: const TextStyle(
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
          ),

          // ── Episodes header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'EPISODES',
                    style: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_loading) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        color: AppTheme.crimson.withValues(alpha: 0.5),
                        strokeWidth: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Episode list ─────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final epNum = widget.startEp + index;
              final isNextAiring =
                  nextAiringEp != null && epNum == nextAiringEp;
              final isUnaired = nextAiringEp != null && epNum >= nextAiringEp;
              final jikanEp = _episodes[epNum];

              return _AnimeEpisodeCard(
                episodeNumber: epNum,
                posterUrl: widget.anime.posterUrl,
                title: jikanEp?.title,
                airDate: jikanEp?.airDateShort,
                score: jikanEp?.score ?? 0,
                isFiller: jikanEp?.filler ?? false,
                isRecap: jikanEp?.recap ?? false,
                isNextAiring: isNextAiring,
                isUnaired: isUnaired,
                nextAiringAt: isNextAiring ? widget.anime.nextAiringAt : null,
                onTap: isUnaired
                    ? null
                    : () => Navigator.pop(context, _buildQuery(epNum)),
              );
            }, childCount: widget.endEp - widget.startEp + 1),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Episode card with thumbnail ──────────────────────────────────────

class _AnimeEpisodeCard extends StatelessWidget {
  final int episodeNumber;
  final String posterUrl;
  final String? title;
  final String? airDate;
  final double score;
  final bool isFiller;
  final bool isRecap;
  final bool isNextAiring;
  final bool isUnaired;
  final DateTime? nextAiringAt;
  final VoidCallback? onTap;

  const _AnimeEpisodeCard({
    required this.episodeNumber,
    required this.posterUrl,
    this.title,
    this.airDate,
    this.score = 0,
    this.isFiller = false,
    this.isRecap = false,
    this.isNextAiring = false,
    this.isUnaired = false,
    this.nextAiringAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eNum = episodeNumber.toString().padLeft(2, '0');
    final epTitle = title != null && title!.isNotEmpty
        ? title!
        : 'Episode $episodeNumber';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Material(
        color: isUnaired
            ? AppTheme.cardDark.withValues(alpha: 0.5)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail row ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Episode thumbnail (uses anime poster)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: SizedBox(
                      width: 140,
                      height: 90,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Poster as background
                          if (posterUrl.isNotEmpty && !isUnaired)
                            Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbnailPlaceholder(eNum),
                            )
                          else
                            _thumbnailPlaceholder(eNum),
                          // Dark overlay with episode number
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isNextAiring
                                    ? [
                                        AppTheme.crimson.withValues(alpha: 0.7),
                                        AppTheme.crimson.withValues(alpha: 0.3),
                                      ]
                                    : isUnaired
                                    ? [
                                        AppTheme.darkSurface.withValues(
                                          alpha: 0.9,
                                        ),
                                        AppTheme.darkSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ]
                                    : [
                                        Colors.black.withValues(alpha: 0.55),
                                        Colors.black.withValues(alpha: 0.25),
                                      ],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    eNum,
                                    style: TextStyle(
                                      color: isUnaired && !isNextAiring
                                          ? AppTheme.textMuted.withValues(
                                              alpha: 0.3,
                                            )
                                          : Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (isNextAiring)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NEXT',
                                        style: TextStyle(
                                          color: AppTheme.crimson,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Episode info ─────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // EP tag row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isNextAiring || !isUnaired
                                      ? AppTheme.crimson.withValues(alpha: 0.15)
                                      : AppTheme.darkSurface.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'EP $eNum',
                                  style: TextStyle(
                                    color: isUnaired && !isNextAiring
                                        ? AppTheme.textMuted.withValues(
                                            alpha: 0.4,
                                          )
                                        : AppTheme.crimson,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (score > 0 && !isUnaired)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      score.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              if (isFiller) _tag('FILLER', Colors.orange),
                              if (isRecap) _tag('RECAP', AppTheme.purple),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Episode title
                          Text(
                            epTitle,
                            style: TextStyle(
                              color: isUnaired
                                  ? AppTheme.textMuted.withValues(alpha: 0.4)
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Air date or airing status
                          if (isNextAiring && nextAiringAt != null)
                            Text(
                              _formatAiringTime(nextAiringAt!),
                              style: TextStyle(
                                color: AppTheme.crimson.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            )
                          else if (isUnaired)
                            Text(
                              'Not yet aired',
                              style: TextStyle(
                                color: AppTheme.textMuted.withValues(
                                  alpha: 0.3,
                                ),
                                fontSize: 11,
                              ),
                            )
                          else if (airDate != null && airDate!.isNotEmpty)
                            Text(
                              airDate!,
                              style: TextStyle(
                                color: AppTheme.textMuted.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static Widget _thumbnailPlaceholder(String eNum) {
    return Container(
      color: AppTheme.darkSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              color: AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'EP $eNum',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatAiringTime(DateTime airingAt) {
    final now = DateTime.now();
    final diff = airingAt.difference(now);
    if (diff.isNegative) return 'Airing soon';
    if (diff.inDays > 0) {
      return 'Airs in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return 'Airs in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'Airs in ${diff.inMinutes}m';
  }
}
