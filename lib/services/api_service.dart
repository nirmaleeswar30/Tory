import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/torrent.dart';

class ApiResult {
  final List<Torrent> torrents;
  final String? error;

  ApiResult({required this.torrents, this.error});
}

class ApiService {
  final http.Client _client = http.Client();

  /// Search a torrent source.
  ///
  /// [baseUrl] – your tory-server instance (e.g. https://tory-server.vercel.app)
  /// [source]  – site keyword ("1337x", "yts", "all", …)
  /// [query]   – search term
  /// [page]    – optional page number
  Future<ApiResult> search({
    required String baseUrl,
    required String source,
    required String query,
    int page = 1,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = page > 1
          ? '$baseUrl/api/$source/$encodedQuery/$page'
          : '$baseUrl/api/$source/$encodedQuery';

      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return ApiResult(
          torrents: [],
          error: 'Server error (${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body);

      // API error envelope: { "error": "…" }
      if (data is Map && data.containsKey('error') && data['error'] is String) {
        return ApiResult(torrents: [], error: data['error'] as String);
      }

      // Flatten response into a list of torrent maps.
      // The "all" endpoint returns a flat list, but some items can be
      // nested arrays or nulls from failed scrapers.
      // Single-source endpoints return a plain list of maps.
      final List<Map<String, dynamic>> items = [];

      if (data is List) {
        _extractItems(data, items);
      } else if (data is Map) {
        // Some API forks return { "source": [...], ... } for "all".
        for (final value in data.values) {
          if (value is List) {
            _extractItems(value, items);
          }
        }
      }

      if (items.isEmpty && data is! Map && data is! List) {
        return ApiResult(torrents: [], error: 'Unexpected response format');
      }

      final torrents = items
          .map(
            (item) => Torrent.fromJson(
              item,
              source == 'all' ? _guessSource(item) : source,
            ),
          )
          .toList();
      return ApiResult(torrents: torrents);
    } on TimeoutException {
      return ApiResult(torrents: [], error: 'Request timed out');
    } catch (e) {
      return ApiResult(torrents: [], error: 'Connection error: $e');
    }
  }

  /// Recursively extract Map items from a potentially nested list.
  void _extractItems(List<dynamic> list, List<Map<String, dynamic>> out) {
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        out.add(item);
      } else if (item is Map) {
        // Cast loosely-typed maps.
        out.add(Map<String, dynamic>.from(item));
      } else if (item is List) {
        // Nested arrays from aggregated sources.
        _extractItems(item, out);
      }
      // Skip nulls and other non-map items.
    }
  }

  /// When using the "all" aggregator the API doesn't tag the source,
  /// so we guess it from the result URL.
  String _guessSource(Map<String, dynamic> item) {
    final url = (item['Url'] as String? ?? '').toLowerCase();
    if (url.contains('1337x')) return '1337x';
    if (url.contains('yts')) return 'yts';
    if (url.contains('eztv')) return 'eztv';
    if (url.contains('piratebay') || url.contains('hiddenbay')) {
      return 'piratebay';
    }
    if (url.contains('torlock')) return 'torlock';
    if (url.contains('torrentgalaxy')) return 'tgx';
    if (url.contains('rarbg') || url.contains('rargb')) return 'rarbg';
    if (url.contains('nyaa')) return 'nyaasi';
    if (url.contains('ettv')) return 'ettv';
    if (url.contains('zooqle')) return 'zooqle';
    if (url.contains('kickass')) return 'kickass';
    if (url.contains('bitsearch')) return 'bitsearch';
    if (url.contains('glodls')) return 'glodls';
    if (url.contains('magnetdl')) return 'magnetdl';
    if (url.contains('limetorrent')) return 'limetorrent';
    if (url.contains('torrentfunk')) return 'torrentfunk';
    if (url.contains('torrentproject')) return 'torrentproject';
    return 'unknown';
  }

  void dispose() {
    _client.close();
  }
}
