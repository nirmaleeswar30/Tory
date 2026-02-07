import 'package:flutter/foundation.dart';

import '../models/torrent.dart';
import '../services/storage_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final StorageService _storage;
  List<Torrent> _favorites = [];

  FavoritesProvider(this._storage);

  List<Torrent> get favorites => _favorites;

  void load() {
    _favorites = _storage.getFavorites();
    notifyListeners();
  }

  Future<void> toggle(Torrent torrent) async {
    if (isFavorite(torrent)) {
      await _storage.removeFavorite(torrent);
    } else {
      await _storage.addFavorite(torrent);
    }
    load();
  }

  bool isFavorite(Torrent torrent) => _storage.isFavorite(torrent);

  Future<void> remove(Torrent torrent) async {
    await _storage.removeFavorite(torrent);
    load();
  }
}
