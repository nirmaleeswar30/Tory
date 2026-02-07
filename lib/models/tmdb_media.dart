class TmdbMedia {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final String releaseDate;
  final String mediaType; // 'movie' or 'tv'
  final List<int> genreIds;
  final String originalLanguage;
  final String? nextEpisodeAirDate;

  TmdbMedia({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    required this.releaseDate,
    required this.mediaType,
    this.genreIds = const [],
    this.originalLanguage = '',
    this.nextEpisodeAirDate,
  });

  factory TmdbMedia.fromJson(Map<String, dynamic> json, {String? type}) {
    final mediaType = type ?? json['media_type'] as String? ?? 'movie';
    return TmdbMedia(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? 'Unknown') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      overview: (json['overview'] ?? '') as String,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate:
          (json['release_date'] ?? json['first_air_date'] ?? '') as String,
      mediaType: mediaType,
      genreIds:
          (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      originalLanguage: (json['original_language'] ?? '') as String,
    );
  }

  TmdbMedia copyWith({String? nextEpisodeAirDate}) => TmdbMedia(
    id: id,
    title: title,
    posterPath: posterPath,
    backdropPath: backdropPath,
    overview: overview,
    voteAverage: voteAverage,
    releaseDate: releaseDate,
    mediaType: mediaType,
    genreIds: genreIds,
    originalLanguage: originalLanguage,
    nextEpisodeAirDate: nextEpisodeAirDate ?? this.nextEpisodeAirDate,
  );

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : '';

  String get year {
    if (releaseDate.length >= 4) return releaseDate.substring(0, 4);
    return '';
  }

  /// The search term we'll use when tapping this card.
  String get searchQuery {
    if (year.isNotEmpty) return '$title $year';
    return title;
  }
}
