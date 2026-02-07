class AppConstants {
  AppConstants._();

  static const String defaultApiBaseUrl = 'https://tory-server.vercel.app';
  static const String defaultTmdbApiKey = 'd39245e111947eb92b947e3a8aacc89f';

  static const List<String> availableSources = [
    'all',
    '1337x',
    'yts',
    'eztv',
    'piratebay',
    'torlock',
    'tgx',
    'rarbg',
    'nyaasi',
    'ettv',
    'zooqle',
    'kickass',
    'bitsearch',
    'glodls',
    'magnetdl',
    'limetorrent',
    'torrentfunk',
    'torrentproject',
  ];

  static const Map<String, String> sourceDisplayNames = {
    'all': 'All Sources',
    '1337x': '1337x',
    'yts': 'YTS',
    'eztv': 'EZTV',
    'piratebay': 'PirateBay',
    'torlock': 'Torlock',
    'tgx': 'TorrentGalaxy',
    'rarbg': 'RARBG',
    'nyaasi': 'NyaaSi',
    'ettv': 'ETTV',
    'zooqle': 'Zooqle',
    'kickass': 'KickAss',
    'bitsearch': 'BitSearch',
    'glodls': 'GloTorrents',
    'magnetdl': 'MagnetDL',
    'limetorrent': 'LimeTorrent',
    'torrentfunk': 'TorrentFunk',
    'torrentproject': 'TorrentProject',
  };

  static const Map<String, String> sourceEmojis = {
    'all': '🌐',
    '1337x': '🔥',
    'yts': '🎬',
    'eztv': '📺',
    'piratebay': '🏴\u200d☠️',
    'torlock': '🔒',
    'tgx': '🌌',
    'rarbg': '⚡',
    'nyaasi': '🎌',
    'ettv': '📡',
    'zooqle': '🔍',
    'kickass': '💥',
    'bitsearch': '🔎',
    'glodls': '🌍',
    'magnetdl': '🧲',
    'limetorrent': '🍋',
    'torrentfunk': '🎵',
    'torrentproject': '📋',
  };

  static const Map<String, double> sourceReliability = {
    '1337x': 0.9,
    'yts': 0.95,
    'eztv': 0.85,
    'piratebay': 0.8,
    'torlock': 0.7,
    'tgx': 0.85,
    'rarbg': 0.9,
    'nyaasi': 0.9,
    'ettv': 0.75,
    'zooqle': 0.7,
    'kickass': 0.75,
    'bitsearch': 0.75,
    'glodls': 0.7,
    'magnetdl': 0.7,
    'limetorrent': 0.65,
    'torrentfunk': 0.65,
    'torrentproject': 0.7,
  };

  static const List<Map<String, String>> categories = [
    {'name': 'Movies', 'icon': '🎬', 'source': 'yts'},
    {'name': 'Anime', 'icon': '🎌', 'source': 'nyaasi'},
    {'name': 'TV Shows', 'icon': '📺', 'source': 'eztv'},
    {'name': 'Games', 'icon': '🎮', 'source': '1337x'},
    {'name': 'Music', 'icon': '🎵', 'source': '1337x'},
    {'name': 'Software', 'icon': '💻', 'source': '1337x'},
  ];

  static const int searchDebounceMs = 500;
  static const int maxRecentSearches = 20;
}
