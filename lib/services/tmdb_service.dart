import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tmdb_media.dart';

class TmdbService {
  final http.Client _client = http.Client();
  static const _baseUrl = 'https://api.themoviedb.org/3';

  /// Fetch trending movies (week).
  Future<List<TmdbMedia>> getTrendingMovies(String apiKey) =>
      _fetch('$_baseUrl/trending/movie/week?api_key=$apiKey', type: 'movie');

  /// Fetch trending TV shows (week).
  Future<List<TmdbMedia>> getTrendingTV(String apiKey) =>
      _fetch('$_baseUrl/trending/tv/week?api_key=$apiKey', type: 'tv');

  /// Fetch popular anime-tagged TV (genre 16 = Animation, language = ja).
  Future<List<TmdbMedia>> getPopularAnime(String apiKey) => _fetch(
    '$_baseUrl/discover/tv?api_key=$apiKey'
    '&with_genres=16&with_original_language=ja&sort_by=popularity.desc',
    type: 'tv',
  );

  /// Fetch trending anime — multiple sources for more results.
  Future<List<TmdbMedia>> getTrendingAnime(String apiKey) async {
    // Pull from trending TV (3 pages) + discover sorted by trending for anime.
    final results = await Future.wait([
      _fetch('$_baseUrl/trending/tv/week?api_key=$apiKey&page=1', type: 'tv'),
      _fetch('$_baseUrl/trending/tv/week?api_key=$apiKey&page=2', type: 'tv'),
      _fetch('$_baseUrl/trending/tv/week?api_key=$apiKey&page=3', type: 'tv'),
      _fetch(
        '$_baseUrl/discover/tv?api_key=$apiKey'
        '&with_genres=16&with_original_language=ja&sort_by=trending.desc',
        type: 'tv',
      ),
    ]);
    final Map<int, TmdbMedia> seen = {};
    for (final list in results) {
      for (final m in list) {
        if (m.genreIds.contains(16) &&
            m.originalLanguage == 'ja' &&
            !seen.containsKey(m.id)) {
          seen[m.id] = m;
        }
      }
    }
    return seen.values.toList();
  }

  /// Fetch latest airing anime — currently on air, sorted by next episode air date.
  Future<List<TmdbMedia>> getLatestAnime(String apiKey) async {
    // Fetch multiple pages from both airing_today and on_the_air for broad coverage.
    final results = await Future.wait([
      _fetch('$_baseUrl/tv/airing_today?api_key=$apiKey&page=1', type: 'tv'),
      _fetch('$_baseUrl/tv/airing_today?api_key=$apiKey&page=2', type: 'tv'),
      _fetch('$_baseUrl/tv/airing_today?api_key=$apiKey&page=3', type: 'tv'),
      _fetch('$_baseUrl/tv/on_the_air?api_key=$apiKey&page=1', type: 'tv'),
      _fetch('$_baseUrl/tv/on_the_air?api_key=$apiKey&page=2', type: 'tv'),
      _fetch('$_baseUrl/tv/on_the_air?api_key=$apiKey&page=3', type: 'tv'),
      _fetch('$_baseUrl/tv/on_the_air?api_key=$apiKey&page=4', type: 'tv'),
    ]);

    // Combine, deduplicate, filter to Japanese animation.
    final Map<int, TmdbMedia> seen = {};
    for (final list in results) {
      for (final m in list) {
        if (m.genreIds.contains(16) &&
            m.originalLanguage == 'ja' &&
            !seen.containsKey(m.id)) {
          seen[m.id] = m;
        }
      }
    }

    // Fetch show details in parallel to get next episode air dates.
    final detailed = await Future.wait(
      seen.values.map((m) => _enrichWithEpisodeDate(m, apiKey)),
    );

    // Sort by next episode air date descending (most recent first),
    // falling back to first_air_date for shows without episode info.
    detailed.sort((a, b) {
      final aDate = a.nextEpisodeAirDate ?? a.releaseDate;
      final bDate = b.nextEpisodeAirDate ?? b.releaseDate;
      return bDate.compareTo(aDate);
    });

    return detailed;
  }

  /// Fetch show details and extract next/last episode air date.
  Future<TmdbMedia> _enrichWithEpisodeDate(
    TmdbMedia media,
    String apiKey,
  ) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/tv/${media.id}?api_key=$apiKey'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Prefer next episode (upcoming), fall back to last episode (most recent aired).
        final next = data['next_episode_to_air'] as Map<String, dynamic>?;
        final last = data['last_episode_to_air'] as Map<String, dynamic>?;
        final airDate = (next?['air_date'] ?? last?['air_date']) as String?;
        if (airDate != null && airDate.isNotEmpty) {
          return media.copyWith(nextEpisodeAirDate: airDate);
        }
      }
    } catch (_) {}
    return media;
  }

  // ── Private ──────────────────────────────────────────────────────────

  Future<List<TmdbMedia>> _fetch(String url, {required String type}) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final results = data['results'] as List? ?? [];

      return results
          .map((e) => TmdbMedia.fromJson(e as Map<String, dynamic>, type: type))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() => _client.close();
}
