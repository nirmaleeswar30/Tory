import 'package:shared_preferences/shared_preferences.dart';

import '../models/torrent.dart';

class StorageService {
  static const _favoritesKey = 'favorites';
  static const _recentSearchesKey = 'recent_searches';
  static const _apiBaseUrlKey = 'api_base_url';
  static const _defaultSourceKey = 'default_source';
  static const _tmdbApiKeyKey = 'tmdb_api_key';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Favorites ────────────────────────────────────────────────────────

  List<Torrent> getFavorites() {
    final data = _prefs.getStringList(_favoritesKey) ?? [];
    return data.map((e) => Torrent.fromJsonString(e)).toList();
  }

  Future<void> saveFavorites(List<Torrent> favorites) async {
    final data = favorites.map((e) => e.toJsonString()).toList();
    await _prefs.setStringList(_favoritesKey, data);
  }

  Future<void> addFavorite(Torrent torrent) async {
    final favorites = getFavorites();
    final isDuplicate = favorites.any(
      (f) =>
          (f.magnet != null && f.magnet == torrent.magnet) ||
          (f.name == torrent.name && f.source == torrent.source),
    );
    if (!isDuplicate) {
      favorites.insert(0, torrent);
      await saveFavorites(favorites);
    }
  }

  Future<void> removeFavorite(Torrent torrent) async {
    final favorites = getFavorites();
    favorites.removeWhere(
      (f) =>
          (f.magnet != null && f.magnet == torrent.magnet) ||
          (f.name == torrent.name && f.source == torrent.source),
    );
    await saveFavorites(favorites);
  }

  bool isFavorite(Torrent torrent) {
    final favorites = getFavorites();
    return favorites.any(
      (f) =>
          (f.magnet != null && f.magnet == torrent.magnet) ||
          (f.name == torrent.name && f.source == torrent.source),
    );
  }

  // ── Recent searches ──────────────────────────────────────────────────

  List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    final searches = getRecentSearches();
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 20) searches.removeRange(20, searches.length);
    await _prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> removeRecentSearch(String query) async {
    final searches = getRecentSearches();
    searches.remove(query);
    await _prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.setStringList(_recentSearchesKey, []);
  }

  // ── Settings ─────────────────────────────────────────────────────────

  String getApiBaseUrl() {
    return _prefs.getString(_apiBaseUrlKey) ?? '';
  }

  Future<void> setApiBaseUrl(String url) async {
    await _prefs.setString(_apiBaseUrlKey, url);
  }

  String getDefaultSource() {
    return _prefs.getString(_defaultSourceKey) ?? 'all';
  }

  Future<void> setDefaultSource(String source) async {
    await _prefs.setString(_defaultSourceKey, source);
  }

  String getTmdbApiKey() {
    return _prefs.getString(_tmdbApiKeyKey) ?? '';
  }

  Future<void> setTmdbApiKey(String key) async {
    await _prefs.setString(_tmdbApiKeyKey, key);
  }
}
