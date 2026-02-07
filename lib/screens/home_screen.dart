import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/anilist_media.dart';
import '../models/tmdb_media.dart';
import '../providers/settings_provider.dart';
import '../services/anilist_service.dart';
import '../services/storage_service.dart';
import '../services/tmdb_service.dart';
import '../widgets/anime_card.dart';
import '../widgets/anime_episode_sheet.dart';
import '../widgets/media_card.dart';
import '../widgets/episode_picker_sheet.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TmdbService _tmdb = TmdbService();
  final AnilistService _anilist = AnilistService();

  List<TmdbMedia> _trendingMovies = [];
  List<TmdbMedia> _trendingTV = [];
  List<AnilistMedia> _popularAnime = [];
  List<AnilistMedia> _trendingAnime = [];
  List<AnilistMedia> _latestAnime = [];
  bool _tmdbLoading = true;
  bool _animeLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTmdb();
      _loadAnime();
    });
  }

  Future<void> _loadTmdb() async {
    final key = context.read<SettingsProvider>().tmdbApiKey;
    if (key.isEmpty) {
      if (mounted) setState(() => _tmdbLoading = false);
      return;
    }

    final results = await Future.wait([
      _tmdb.getTrendingMovies(key),
      _tmdb.getTrendingTV(key),
    ]);

    if (mounted) {
      setState(() {
        _trendingMovies = results[0];
        _trendingTV = results[1];
        _tmdbLoading = false;
      });
    }
  }

  Future<void> _loadAnime() async {
    final results = await Future.wait([
      _anilist.getTrendingAnime(),
      _anilist.getPopularAnime(),
      _anilist.getLatestAnime(),
    ]);

    if (mounted) {
      setState(() {
        _trendingAnime = results[0];
        _popularAnime = results[1];
        _latestAnime = results[2];
        _animeLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tmdb.dispose();
    _anilist.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final storage = context.read<StorageService>();
    final recentSearches = storage.getRecentSearches();

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tory',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar (tappable) ──────────────────────────────
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () => _navigateToSearch(context),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.textMuted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppTheme.textMuted,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Search movies, anime, shows...',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Quick sources ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Text(
                  'QUICK SOURCES',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  itemCount: AppConstants.availableSources.length,
                  itemBuilder: (context, index) {
                    final source = AppConstants.availableSources[index];
                    final emoji = AppConstants.sourceEmojis[source] ?? '📦';
                    final name =
                        AppConstants.sourceDisplayNames[source] ?? source;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Text(
                          emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        label: Text(name),
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        backgroundColor: AppTheme.cardDark,
                        side: BorderSide(
                          color: AppTheme.textMuted.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: () =>
                            _navigateToSearch(context, source: source),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Trending Movies ─────────────────────────────────
            if (_tmdbLoading && _animeLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.crimson,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else ...[
              if (_trendingMovies.isNotEmpty)
                _tmdbSection('TRENDING MOVIES', '🎬', _trendingMovies, 'all'),
              if (_trendingTV.isNotEmpty)
                _tmdbSection('TRENDING TV SHOWS', '📺', _trendingTV, 'all'),
              if (_latestAnime.isNotEmpty)
                _animeSection('LATEST ANIME', '✨', _latestAnime),
              if (_trendingAnime.isNotEmpty)
                _animeSection('TRENDING ANIME', '🔥', _trendingAnime),
              if (_popularAnime.isNotEmpty)
                _animeSection('POPULAR ANIME', '🎌', _popularAnime),
            ],

            // ── Recent searches ────────────────────────────────────
            if (recentSearches.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RECENT SEARCHES',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await storage.clearRecentSearches();
                          if (mounted) setState(() {});
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: AppTheme.crimson,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final query = recentSearches[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.history_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    title: Text(
                      query,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.north_west_rounded,
                      color: AppTheme.textMuted,
                      size: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    dense: true,
                    onTap: () =>
                        _navigateToSearch(context, prefilledQuery: query),
                  );
                }, childCount: recentSearches.length.clamp(0, 10)),
              ),
            ],

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Anime card tap handler ────────────────────────────────────────

  void _onAnimeTap(BuildContext context, AnilistMedia anime) async {
    final query = await showAnimeEpisodeSheet(context, anime: anime);
    if (query != null && query.isNotEmpty && mounted) {
      if (!context.mounted) return;
      // Build an alternative query for better torrent coverage.
      // Primary:  "Title S02E03"  →  Alt: "Title S2 - 03"
      // Primary:  "Title S02"    →  Alt: "Title Season 2"
      // Primary:  "Title"        →  Alt: null (no need)
      final altQuery = _buildAnimeAltQuery(query, anime);
      _navigateToSearch(
        context,
        source: 'nyaasi',
        prefilledQuery: query,
        altQuery: altQuery,
      );
    }
  }

  /// Build alternative anime search format for dual-search.
  /// SubsPlease format: "Title - 03" (S1) or "Title S2 - 03" (S2+)
  String? _buildAnimeAltQuery(String primary, AnilistMedia anime) {
    final title = anime.shortSearchQuery;
    final sNum = anime.seasonNumber;

    // Match "Title S02E03"
    final epMatch = RegExp(r'S(\d+)E(\d+)$').firstMatch(primary);
    if (epMatch != null) {
      final ep = int.parse(epMatch.group(2)!);
      final epStr = ep.toString().padLeft(2, '0');
      // S1: "Title - 03", S2+: "Title S2 - 03"
      if (sNum <= 1) return '$title - $epStr';
      return '$title S$sNum - $epStr';
    }

    // Match "Title S02" (range search)
    final sMatch = RegExp(r'S(\d+)$').firstMatch(primary);
    if (sMatch != null) {
      if (sNum <= 1) return title; // just the title for S1
      return '$title S$sNum';
    }

    // Full title search — no alt needed
    return null;
  }

  // ── Media card tap handler ─────────────────────────────────────────

  void _onMediaTap(
    BuildContext context,
    TmdbMedia media,
    String defaultSource,
  ) async {
    if (media.mediaType == 'movie') {
      _navigateToSearch(
        context,
        source: defaultSource,
        prefilledQuery: media.searchQuery,
      );
      return;
    }
    // TV / Anime → show season/episode picker
    final apiKey = context.read<SettingsProvider>().tmdbApiKey;
    final query = await showEpisodePickerSheet(
      context,
      media: media,
      tmdbApiKey: apiKey,
    );
    if (query != null && query.isNotEmpty && mounted) {
      if (!context.mounted) return;
      _navigateToSearch(context, source: defaultSource, prefilledQuery: query);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────

  void _navigateToSearch(
    BuildContext context, {
    String source = 'all',
    String prefilledQuery = '',
    String? altQuery,
  }) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(
          initialSource: source,
          initialQuery: prefilledQuery,
          altQuery: altQuery,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    // Refresh recent searches after returning from search.
    if (mounted) setState(() {});
  }

  // ── AniList horizontal section builder ─────────────────────────────

  Widget _animeSection(String title, String emoji, List<AnilistMedia> items) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final anime = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: AnimeCard(
                    anime: anime,
                    onTap: () => _onAnimeTap(context, anime),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── TMDB horizontal section builder ────────────────────────────────

  Widget _tmdbSection(
    String title,
    String emoji,
    List<TmdbMedia> items,
    String defaultSource,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final media = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: MediaCard(
                    media: media,
                    onTap: () => _onMediaTap(context, media, defaultSource),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
