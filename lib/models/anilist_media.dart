class AnilistMedia {
  final int id;
  final int? idMal;
  final String titleRomaji;
  final String titleEnglish;
  final String? coverImageLarge;
  final String? bannerImage;
  final int? averageScore;
  final int? episodes;
  final String? status;
  final String? season;
  final int? seasonYear;
  final List<String> genres;
  final String? format;
  final int? nextAiringEpisode;
  final DateTime? nextAiringAt;

  AnilistMedia({
    required this.id,
    this.idMal,
    required this.titleRomaji,
    required this.titleEnglish,
    this.coverImageLarge,
    this.bannerImage,
    this.averageScore,
    this.episodes,
    this.status,
    this.season,
    this.seasonYear,
    this.genres = const [],
    this.format,
    this.nextAiringEpisode,
    this.nextAiringAt,
  });

  factory AnilistMedia.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>? ?? {};
    final cover = json['coverImage'] as Map<String, dynamic>? ?? {};
    final nextAiring = json['nextAiringEpisode'] as Map<String, dynamic>?;

    DateTime? airingAt;
    if (nextAiring != null && nextAiring['airingAt'] != null) {
      airingAt = DateTime.fromMillisecondsSinceEpoch(
        (nextAiring['airingAt'] as int) * 1000,
      );
    }

    return AnilistMedia(
      id: json['id'] as int,
      idMal: json['idMal'] as int?,
      titleRomaji: (title['romaji'] ?? '') as String,
      titleEnglish: (title['english'] ?? '') as String,
      coverImageLarge: cover['large'] as String?,
      bannerImage: json['bannerImage'] as String?,
      averageScore: json['averageScore'] as int?,
      episodes: json['episodes'] as int?,
      status: json['status'] as String?,
      season: json['season'] as String?,
      seasonYear: json['seasonYear'] as int?,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => g as String)
              .toList() ??
          [],
      format: json['format'] as String?,
      nextAiringEpisode: nextAiring?['episode'] as int?,
      nextAiringAt: airingAt,
    );
  }

  /// Display title — prefer English, fall back to Romaji.
  String get displayTitle =>
      titleEnglish.isNotEmpty ? titleEnglish : titleRomaji;

  String get posterUrl => coverImageLarge ?? '';

  String get year => seasonYear?.toString() ?? '';

  double get rating => (averageScore ?? 0) / 10.0; // 0–10 scale

  String get formatLabel => switch (format) {
    'TV' => 'TV',
    'TV_SHORT' => 'SHORT',
    'MOVIE' => 'MOVIE',
    'SPECIAL' => 'SP',
    'OVA' => 'OVA',
    'ONA' => 'ONA',
    'MUSIC' => 'MV',
    _ => format ?? '',
  };

  /// Search query used when user taps the card.
  /// Strips season suffixes (e.g. "2nd Season", "Part 3") so the
  /// S##E## format added later doesn't conflict.
  String get searchQuery {
    final raw = titleRomaji.isNotEmpty ? titleRomaji : titleEnglish;
    // If romaji has a season indicator, strip it.
    if (_hasSeasonIndicator(raw)) return _stripSeasonSuffix(raw);
    // If English has a season indicator but romaji doesn't (subtitle-style),
    // still strip from whichever has it, but prefer romaji base.
    if (titleEnglish.isNotEmpty && _hasSeasonIndicator(titleEnglish)) {
      return _stripSeasonSuffix(raw);
    }
    return raw;
  }

  /// Short title for SubsPlease-style searches — strips subtitles after
  /// colons (e.g. "Yuusha-kei ni Shosu: Choubatsu..." → "Yuusha-kei ni Shosu").
  String get shortSearchQuery {
    final full = searchQuery;
    // Strip everything after first colon or long-dash subtitle separator
    final colonIdx = full.indexOf(':');
    final dashIdx = full.indexOf(' - ');
    int cutAt = -1;
    if (colonIdx > 3) cutAt = colonIdx;
    if (dashIdx > 3 && (cutAt == -1 || dashIdx < cutAt)) cutAt = dashIdx;
    if (cutAt > 3) return full.substring(0, cutAt).trim();
    return full;
  }

  /// Season number extracted from the title (e.g. "2nd Season" → 2).
  /// Checks both romaji and English titles, falls back to 1.
  int get seasonNumber {
    // Check romaji first
    final romaji = titleRomaji.isNotEmpty ? titleRomaji : '';
    if (_hasSeasonIndicator(romaji)) return _extractSeasonNumber(romaji);
    // Fall back to English
    if (titleEnglish.isNotEmpty && _hasSeasonIndicator(titleEnglish)) {
      return _extractSeasonNumber(titleEnglish);
    }
    return 1;
  }

  static bool _hasSeasonIndicator(String title) {
    for (final p in _seasonPatterns) {
      if (p.hasMatch(title)) return true;
    }
    return false;
  }

  static final _seasonPatterns = [
    // "2nd Season", "3rd Season", "Season 2", etc.
    RegExp(r'\b(\d+)(?:st|nd|rd|th)\s+season\b', caseSensitive: false),
    RegExp(r'\bseason\s+(\d+)\b', caseSensitive: false),
    // "Part 2", "Cour 2"
    RegExp(r'\bpart\s+(\d+)\b', caseSensitive: false),
    RegExp(r'\bcour\s+(\d+)\b', caseSensitive: false),
    // Roman numerals at end: "Title II", "Title III", "Title IV"
    RegExp(r'\s+(IV|III|II)\s*$', caseSensitive: false),
  ];

  static final _stripPatterns = [
    RegExp(r'\s*[-:]\s*\d+(?:st|nd|rd|th)\s+season\b', caseSensitive: false),
    RegExp(r'\s*\d+(?:st|nd|rd|th)\s+season\b', caseSensitive: false),
    RegExp(r'\s*[-:]\s*season\s+\d+\b', caseSensitive: false),
    RegExp(r'\s*season\s+\d+\b', caseSensitive: false),
    RegExp(r'\s*[-:]\s*part\s+\d+\b', caseSensitive: false),
    RegExp(r'\s*part\s+\d+\b', caseSensitive: false),
    RegExp(r'\s*[-:]\s*cour\s+\d+\b', caseSensitive: false),
    RegExp(r'\s*cour\s+\d+\b', caseSensitive: false),
    RegExp(r'\s+(IV|III|II)\s*$', caseSensitive: false),
  ];

  static String _stripSeasonSuffix(String title) {
    var result = title;
    for (final p in _stripPatterns) {
      result = result.replaceAll(p, '');
    }
    return result.trim();
  }

  static int _extractSeasonNumber(String title) {
    for (final p in _seasonPatterns) {
      final match = p.firstMatch(title);
      if (match != null) {
        final g = match.group(1)!;
        // Handle roman numerals
        if (g.toUpperCase() == 'II') return 2;
        if (g.toUpperCase() == 'III') return 3;
        if (g.toUpperCase() == 'IV') return 4;
        return int.tryParse(g) ?? 1;
      }
    }
    return 1;
  }

  /// Episode count text.
  String get episodesLabel {
    if (episodes != null && episodes! > 0) return '$episodes eps';
    if (status == 'RELEASING') return 'Airing';
    return '?';
  }
}
