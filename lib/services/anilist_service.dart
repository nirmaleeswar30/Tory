import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/anilist_media.dart';

class AnilistService {
  final http.Client _client = http.Client();
  static const _url = 'https://graphql.anilist.co';

  static const _mediaFields = '''
    id
    idMal
    title { romaji english }
    coverImage { large }
    bannerImage
    averageScore
    episodes
    status
    season
    seasonYear
    genres
    format
    nextAiringEpisode { airingAt episode }
  ''';

  /// Trending anime right now.
  Future<List<AnilistMedia>> getTrendingAnime({int perPage = 20}) =>
      _query(sort: 'TRENDING_DESC', perPage: perPage);

  /// Most popular anime of all time.
  Future<List<AnilistMedia>> getPopularAnime({int perPage = 20}) =>
      _query(sort: 'POPULARITY_DESC', perPage: perPage);

  /// Currently airing anime, sorted by most recently updated.
  Future<List<AnilistMedia>> getLatestAnime({int perPage = 25}) async {
    const query =
        '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(
            type: ANIME
            status: RELEASING
            sort: [UPDATED_AT_DESC]
            isAdult: false
          ) {
            $_mediaFields
          }
        }
      }
    ''';

    return _execute(query, {'page': 1, 'perPage': perPage});
  }

  /// Upcoming next season anime.
  Future<List<AnilistMedia>> getUpcomingAnime({int perPage = 20}) async {
    final now = DateTime.now();
    final nextSeason = _getNextSeason(now.month);
    final nextYear = (now.month >= 10) ? now.year + 1 : now.year;

    const query =
        '''
      query (\$page: Int, \$perPage: Int, \$season: MediaSeason, \$seasonYear: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(
            type: ANIME
            season: \$season
            seasonYear: \$seasonYear
            sort: [POPULARITY_DESC]
            isAdult: false
          ) {
            $_mediaFields
          }
        }
      }
    ''';

    return _execute(query, {
      'page': 1,
      'perPage': perPage,
      'season': nextSeason,
      'seasonYear': nextYear,
    });
  }

  // ── Generic query helper ───────────────────────────────────────────

  Future<List<AnilistMedia>> _query({
    required String sort,
    int perPage = 20,
  }) async {
    final query =
        '''
      query (\$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          media(type: ANIME, sort: [$sort], isAdult: false) {
            $_mediaFields
          }
        }
      }
    ''';

    return _execute(query, {'page': 1, 'perPage': perPage});
  }

  Future<List<AnilistMedia>> _execute(
    String query,
    Map<String, dynamic> variables,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'query': query, 'variables': variables}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final page = data['data']?['Page'] as Map<String, dynamic>?;
      final mediaList = page?['media'] as List? ?? [];

      return mediaList
          .map((m) => AnilistMedia.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static String _getNextSeason(int month) {
    // Jan-Mar=WINTER, Apr-Jun=SPRING, Jul-Sep=SUMMER, Oct-Dec=FALL
    return switch (month) {
      >= 1 && <= 3 => 'SPRING',
      >= 4 && <= 6 => 'SUMMER',
      >= 7 && <= 9 => 'FALL',
      _ => 'WINTER',
    };
  }

  void dispose() => _client.close();
}
