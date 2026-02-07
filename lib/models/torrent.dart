import 'dart:convert';

import '../core/scoring.dart';

class Torrent {
  final String name;
  final String? magnet;
  final String? poster;
  final String? category;
  final String? type;
  final String? language;
  final String size;
  final double sizeBytes;
  final String? uploadedBy;
  final int downloads;
  final String? lastChecked;
  final String? dateUploaded;
  final int seeders;
  final int leechers;
  final String? url;
  final String? torrentUrl;
  final String source;
  late final double qualityScore;

  Torrent({
    required this.name,
    this.magnet,
    this.poster,
    this.category,
    this.type,
    this.language,
    required this.size,
    this.sizeBytes = 0,
    this.uploadedBy,
    this.downloads = 0,
    this.lastChecked,
    this.dateUploaded,
    this.seeders = 0,
    this.leechers = 0,
    this.url,
    this.torrentUrl,
    required this.source,
    double? qualityScore,
  }) {
    this.qualityScore = qualityScore ?? TorrentScoring.calculateScore(this);
  }

  // ── JSON serialisation ───────────────────────────────────────────────

  factory Torrent.fromJson(Map<String, dynamic> json, String source) {
    final sizeStr = json['Size'] as String? ?? '';
    return Torrent(
      name: json['Name'] as String? ?? 'Unknown',
      magnet: json['Magnet'] as String?,
      poster: json['Poster'] as String?,
      category: json['Category'] as String?,
      type: json['Type'] as String?,
      language: json['Language'] as String?,
      size: sizeStr,
      sizeBytes: TorrentScoring.parseSizeToBytes(sizeStr),
      uploadedBy: (json['UploadedBy'] as String?)?.trim(),
      downloads: _parseInt(json['Downloads']),
      lastChecked: json['LastChecked'] as String?,
      dateUploaded: json['DateUploaded'] as String?,
      seeders: _parseInt(json['Seeders']),
      leechers: _parseInt(json['Leechers']),
      url: json['Url'] as String?,
      torrentUrl: json['Torrent'] as String?,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
    'Name': name,
    'Magnet': magnet,
    'Poster': poster,
    'Category': category,
    'Type': type,
    'Language': language,
    'Size': size,
    'UploadedBy': uploadedBy,
    'Downloads': downloads.toString(),
    'LastChecked': lastChecked,
    'DateUploaded': dateUploaded,
    'Seeders': seeders.toString(),
    'Leechers': leechers.toString(),
    'Url': url,
    'Torrent': torrentUrl,
    'source': source,
  };

  String toJsonString() => jsonEncode(toJson());

  factory Torrent.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Torrent.fromJson(json, json['source'] as String? ?? 'unknown');
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    }
    return 0;
  }

  String get formattedSeeders {
    if (seeders >= 1000) return '${(seeders / 1000).toStringAsFixed(1)}K';
    return seeders.toString();
  }

  String get formattedLeechers {
    if (leechers >= 1000) return '${(leechers / 1000).toStringAsFixed(1)}K';
    return leechers.toString();
  }

  String get formattedDownloads {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    }
    if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }
}
