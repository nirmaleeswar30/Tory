import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../models/tmdb_media.dart';
import '../widgets/episode_picker_sheet.dart';

class EpisodeInfo {
  final int number;
  final String name;
  final String overview;
  final String airDate;
  final String? stillPath;
  final double voteAverage;
  final int runtime;

  EpisodeInfo({
    required this.number,
    required this.name,
    required this.overview,
    required this.airDate,
    this.stillPath,
    this.voteAverage = 0,
    this.runtime = 0,
  });

  String get stillUrl =>
      stillPath != null ? 'https://image.tmdb.org/t/p/w300$stillPath' : '';
}

class EpisodeScreen extends StatefulWidget {
  final TmdbMedia media;
  final SeasonInfo season;
  final String tmdbApiKey;

  const EpisodeScreen({
    super.key,
    required this.media,
    required this.season,
    required this.tmdbApiKey,
  });

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen> {
  List<EpisodeInfo> _episodes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes() async {
    try {
      final url =
          'https://api.themoviedb.org/3/tv/${widget.media.id}/season/${widget.season.number}?api_key=${widget.tmdbApiKey}';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['episodes'] as List? ?? [];
        final parsed = list
            .map(
              (e) => EpisodeInfo(
                number: e['episode_number'] as int? ?? 0,
                name: e['name'] as String? ?? '',
                overview: e['overview'] as String? ?? '',
                airDate: e['air_date'] as String? ?? '',
                stillPath: e['still_path'] as String?,
                voteAverage: (e['vote_average'] as num?)?.toDouble() ?? 0,
                runtime: e['runtime'] as int? ?? 0,
              ),
            )
            .toList();
        if (mounted)
          setState(() {
            _episodes = parsed;
            _loading = false;
          });
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load episodes';
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Network error';
          _loading = false;
        });
      }
    }
  }

  String _buildQuery(int episode) {
    final title = widget.media.title;
    final s = widget.season.number.toString().padLeft(2, '0');
    final e = episode.toString().padLeft(2, '0');
    return '$title S${s}E$e';
  }

  String _buildSeasonQuery() {
    final title = widget.media.title;
    final s = widget.season.number.toString().padLeft(2, '0');
    return '$title Season $s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing app bar with backdrop ─────────────────
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
                  // Backdrop image
                  if (widget.media.backdropUrl.isNotEmpty)
                    Image.network(
                      widget.media.backdropUrl,
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
                  // Show + season info
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.media.title,
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
                                widget.season.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${widget.season.episodeCount} episodes',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 13,
                              ),
                            ),
                            if (widget.season.airDate.length >= 4) ...[
                              const SizedBox(width: 8),
                              Text(
                                '•  ${widget.season.airDate.substring(0, 4)}',
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

          // ── Search full season button ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Material(
                color: AppTheme.crimson.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context, _buildSeasonQuery()),
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
                          'Search full ${widget.season.name}',
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

          // ── Episode header ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'EPISODES',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // ── Episode list ─────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.crimson,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final ep = _episodes[index];
                return _EpisodeCard(
                  episode: ep,
                  seasonNumber: widget.season.number,
                  onTap: () => Navigator.pop(context, _buildQuery(ep.number)),
                );
              }, childCount: _episodes.length),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Episode card with thumbnail ──────────────────────────────────────

class _EpisodeCard extends StatelessWidget {
  final EpisodeInfo episode;
  final int seasonNumber;
  final VoidCallback onTap;

  const _EpisodeCard({
    required this.episode,
    required this.seasonNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sNum = seasonNumber.toString().padLeft(2, '0');
    final eNum = episode.number.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Material(
        color: AppTheme.cardDark,
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
                  // Episode thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: SizedBox(
                      width: 140,
                      height: 90,
                      child: episode.stillUrl.isNotEmpty
                          ? Image.network(
                              episode.stillUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbnailPlaceholder(sNum, eNum),
                            )
                          : _thumbnailPlaceholder(sNum, eNum),
                    ),
                  ),
                  // Episode info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Episode number tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.crimson.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'S${sNum}E$eNum',
                                  style: const TextStyle(
                                    color: AppTheme.crimson,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (episode.voteAverage > 0)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 13,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      episode.voteAverage.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              if (episode.runtime > 0)
                                Text(
                                  '${episode.runtime}m',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Episode name
                          Text(
                            episode.name.isNotEmpty
                                ? episode.name
                                : 'Episode ${episode.number}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Air date
                          if (episode.airDate.isNotEmpty)
                            Text(
                              episode.airDate,
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
              // ── Overview (if available) ──────────────────────
              if (episode.overview.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Text(
                    episode.overview,
                    style: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _thumbnailPlaceholder(String s, String e) {
    return Container(
      color: AppTheme.darkSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.movie_creation_outlined,
              color: AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'S${s}E$e',
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
}
