import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/torrent.dart';
import '../services/api_service.dart';

enum SortBy { score, seeders, leechers, size, latest, name }

class SearchProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Torrent> _results = [];
  List<Torrent> _sortedResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _currentQuery = '';
  String _currentSource = 'all';
  int _currentPage = 1;
  bool _hasMore = true;
  SortBy _sortBy = SortBy.score;
  Timer? _debounceTimer;

  // ── Getters ──────────────────────────────────────────────────────────

  List<Torrent> get results => _sortedResults;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get currentQuery => _currentQuery;
  String get currentSource => _currentSource;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  SortBy get sortBy => _sortBy;

  // ── Public API ───────────────────────────────────────────────────────

  void setSource(String source) {
    _currentSource = source;
    notifyListeners();
  }

  void setSortBy(SortBy sort) {
    _sortBy = sort;
    _applySorting();
    notifyListeners();
  }

  /// Debounced search – call on every keystroke.
  void search(String query, {String? apiBaseUrl}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim(), _currentSource, apiBaseUrl ?? '');
      }
    });
  }

  /// Immediate search – call on submit / explicit tap.
  void searchImmediate(
    String query, {
    String source = 'all',
    String apiBaseUrl = '',
    String? altQuery,
  }) {
    _debounceTimer?.cancel();
    _currentSource = source;
    if (query.trim().isNotEmpty) {
      if (altQuery != null && altQuery.trim().isNotEmpty) {
        _performDualSearch(query.trim(), altQuery.trim(), source, apiBaseUrl);
      } else {
        _performSearch(query.trim(), source, apiBaseUrl);
      }
    }
  }

  /// Load next page of results.
  Future<void> loadMore(String apiBaseUrl) async {
    if (_isLoadingMore || !_hasMore || _currentQuery.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;
    final result = await _apiService.search(
      baseUrl: apiBaseUrl,
      source: _currentSource,
      query: _currentQuery,
      page: _currentPage,
    );

    _isLoadingMore = false;
    if (result.error != null || result.torrents.isEmpty) {
      _hasMore = false;
    } else {
      _results.addAll(result.torrents);
      _applySorting();
    }
    notifyListeners();
  }

  void clear() {
    _debounceTimer?.cancel();
    _results = [];
    _sortedResults = [];
    _error = null;
    _currentQuery = '';
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  // ── Private helpers ──────────────────────────────────────────────────

  Future<void> _performSearch(
    String query,
    String source,
    String apiBaseUrl,
  ) async {
    _currentQuery = query;
    _currentPage = 1;
    _hasMore = true;
    _isLoading = true;
    _error = null;
    _results = [];
    _sortedResults = [];
    notifyListeners();

    final result = await _apiService.search(
      baseUrl: apiBaseUrl,
      source: source,
      query: query,
      page: 1,
    );

    _isLoading = false;
    if (result.error != null) {
      _error = result.error;
    } else {
      _results = result.torrents;
      _hasMore = result.torrents.isNotEmpty;
      _applySorting();
    }
    notifyListeners();
  }

  /// Dual search — runs two queries in parallel and merges results,
  /// deduplicating by magnet link. Used for anime episode searches.
  Future<void> _performDualSearch(
    String query,
    String altQuery,
    String source,
    String apiBaseUrl,
  ) async {
    _currentQuery = query;
    _currentPage = 1;
    _hasMore = false; // no pagination for dual search
    _isLoading = true;
    _error = null;
    _results = [];
    _sortedResults = [];
    notifyListeners();

    final results = await Future.wait([
      _apiService.search(
        baseUrl: apiBaseUrl,
        source: source,
        query: query,
        page: 1,
      ),
      _apiService.search(
        baseUrl: apiBaseUrl,
        source: source,
        query: altQuery,
        page: 1,
      ),
    ]);

    _isLoading = false;

    // Merge and deduplicate by magnet link (or name if no magnet)
    final Set<String> seen = {};
    final List<Torrent> merged = [];

    for (final result in results) {
      if (result.error != null) continue;
      for (final torrent in result.torrents) {
        final mag = torrent.magnet ?? '';
        final key = mag.isNotEmpty ? mag : torrent.name;
        if (seen.add(key)) {
          merged.add(torrent);
        }
      }
    }

    if (merged.isEmpty && results.every((r) => r.error != null)) {
      _error = results.first.error;
    } else {
      _results = merged;
      _applySorting();
    }
    notifyListeners();
  }

  void _applySorting() {
    _sortedResults = List.from(_results);
    switch (_sortBy) {
      case SortBy.score:
        _sortedResults.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
      case SortBy.seeders:
        _sortedResults.sort((a, b) => b.seeders.compareTo(a.seeders));
      case SortBy.leechers:
        _sortedResults.sort((a, b) => b.leechers.compareTo(a.leechers));
      case SortBy.size:
        _sortedResults.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case SortBy.latest:
        _sortedResults.sort((a, b) {
          final aDate = _parseUploadDate(a.dateUploaded);
          final bDate = _parseUploadDate(b.dateUploaded);
          return bDate.compareTo(aDate);
        });
      case SortBy.name:
        _sortedResults.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// Parse relative date strings ("2 hours ago", "3 days ago") into
  /// a comparable DateTime, falling back to epoch for unparseable strings.
  static DateTime _parseUploadDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime(2000);
    final lower = dateStr.toLowerCase().trim();

    // Try absolute date first (e.g. "2025-02-07")
    try {
      return DateTime.parse(dateStr.split(' ').first);
    } catch (_) {}

    final n = _extractNum(lower);
    final now = DateTime.now();

    if (lower.contains('minute') || lower.contains('min')) {
      return now.subtract(Duration(minutes: n));
    }
    if (lower.contains('hour')) {
      return now.subtract(Duration(hours: n));
    }
    if (lower.contains('day')) {
      return now.subtract(Duration(days: n));
    }
    if (lower.contains('week')) {
      return now.subtract(Duration(days: n * 7));
    }
    if (lower.contains('month')) {
      return now.subtract(Duration(days: n * 30));
    }
    if (lower.contains('year')) {
      return now.subtract(Duration(days: n * 365));
    }
    if (lower.contains('just') || lower.contains('now')) return now;

    return DateTime(2000);
  }

  static int _extractNum(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
