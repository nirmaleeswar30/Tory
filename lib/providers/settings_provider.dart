import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  String _apiBaseUrl = AppConstants.defaultApiBaseUrl;
  String _defaultSource = 'all';
  String _tmdbApiKey = AppConstants.defaultTmdbApiKey;

  SettingsProvider(this._storage);

  String get apiBaseUrl => _apiBaseUrl;
  String get defaultSource => _defaultSource;
  String get tmdbApiKey => _tmdbApiKey;

  void load() {
    final stored = _storage.getApiBaseUrl();
    _apiBaseUrl = stored.isNotEmpty ? stored : AppConstants.defaultApiBaseUrl;
    _defaultSource = _storage.getDefaultSource();
    final storedTmdb = _storage.getTmdbApiKey();
    _tmdbApiKey = storedTmdb.isNotEmpty
        ? storedTmdb
        : AppConstants.defaultTmdbApiKey;
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String url) async {
    _apiBaseUrl = url.isNotEmpty ? url : AppConstants.defaultApiBaseUrl;
    await _storage.setApiBaseUrl(_apiBaseUrl);
    notifyListeners();
  }

  Future<void> setDefaultSource(String source) async {
    _defaultSource = source;
    await _storage.setDefaultSource(source);
    notifyListeners();
  }

  Future<void> setTmdbApiKey(String key) async {
    _tmdbApiKey = key.isNotEmpty ? key : AppConstants.defaultTmdbApiKey;
    await _storage.setTmdbApiKey(_tmdbApiKey);
    notifyListeners();
  }
}
