import 'dart:math';

import '../models/torrent.dart';
import 'constants.dart';

class TorrentScoring {
  TorrentScoring._();

  /// Calculate a quality score from 0–100 for a torrent.
  static double calculateScore(Torrent torrent) {
    double score = 0;

    // Seeders (40%) – logarithmic scale rewards high seeder counts
    score += _seederScore(torrent.seeders) * 40;

    // Seeder / Leecher ratio (25%) – healthy swarm indicator
    score += _ratioScore(torrent.seeders, torrent.leechers) * 25;

    // File size reasonableness (15%)
    score += _sizeScore(torrent.sizeBytes) * 15;

    // Upload recency (10%)
    score += _recencyScore(torrent.dateUploaded) * 10;

    // Source reliability (10%)
    score += _sourceScore(torrent.source) * 10;

    // Trusted anime uploader bonus (+5 flat)
    score += _uploaderBonus(torrent.name, torrent.uploadedBy);

    return double.parse(score.clamp(0, 100).toStringAsFixed(1));
  }

  // ── Private helpers ──────────────────────────────────────────────────

  static double _seederScore(int seeders) {
    if (seeders <= 0) return 0;
    return min(1.0, log(seeders + 1) / log(10001));
  }

  static double _ratioScore(int seeders, int leechers) {
    if (seeders <= 0) return 0;
    if (leechers <= 0) return 1.0;
    double ratio = seeders / leechers;
    return min(1.0, ratio / 10);
  }

  static double _sizeScore(double sizeBytes) {
    if (sizeBytes <= 0) return 0.5; // unknown size → neutral
    double sizeMB = sizeBytes / (1024 * 1024);
    if (sizeMB < 50) return 0.2; // suspiciously small
    if (sizeMB < 200) return 0.6;
    if (sizeMB < 15000) return 1.0; // sweet spot for most content
    if (sizeMB < 50000) return 0.8; // large but acceptable (4K)
    return 0.5;
  }

  static double _recencyScore(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0.5;

    final lower = dateStr.toLowerCase();

    if (lower.contains('hour') ||
        lower.contains('minute') ||
        lower.contains('just')) {
      return 1.0;
    }
    if (lower.contains('day')) {
      final n = _extractNumber(lower);
      if (n <= 7) return 0.95;
      if (n <= 30) return 0.85;
      return 0.7;
    }
    if (lower.contains('week')) {
      final n = _extractNumber(lower);
      return n <= 2 ? 0.9 : 0.75;
    }
    if (lower.contains('month')) {
      final n = _extractNumber(lower);
      if (n <= 3) return 0.7;
      if (n <= 6) return 0.6;
      return 0.5;
    }
    if (lower.contains('year')) {
      final n = _extractNumber(lower);
      if (n <= 1) return 0.4;
      if (n <= 3) return 0.3;
      return 0.2;
    }

    // Try parsing an absolute date (e.g. "2020-10-02 17:48")
    try {
      final date = DateTime.parse(dateStr.split(' ').first);
      final daysSince = DateTime.now().difference(date).inDays;
      if (daysSince < 7) return 0.95;
      if (daysSince < 30) return 0.85;
      if (daysSince < 180) return 0.65;
      if (daysSince < 365) return 0.45;
      return 0.25;
    } catch (_) {
      return 0.5;
    }
  }

  static double _sourceScore(String source) {
    return AppConstants.sourceReliability[source] ?? 0.5;
  }

  /// Bonus for trusted anime release groups.
  static double _uploaderBonus(String name, String? uploader) {
    final lower = name.toLowerCase();
    final uploaderLower = (uploader ?? '').toLowerCase();
    const groups = ['subsplease', 'erai-raws', 'erai raws'];
    for (final g in groups) {
      if (lower.contains(g) || uploaderLower.contains(g)) return 5.0;
    }
    return 0;
  }

  static int _extractNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) ?? 1 : 1;
  }

  /// Parse a human-readable size string ("1.2 GB") to bytes.
  static double parseSizeToBytes(String? sizeStr) {
    if (sizeStr == null || sizeStr.isEmpty) return 0;
    final regex = RegExp(
      r'([\d.]+)\s*(TB|TiB|GB|GiB|MB|MiB|KB|KiB|B)\b',
      caseSensitive: false,
    );
    final match = regex.firstMatch(sizeStr);
    if (match == null) return 0;

    double value = double.tryParse(match.group(1)!) ?? 0;
    String unit = match.group(2)!.toUpperCase();

    return switch (unit) {
      'B' => value,
      'KB' || 'KIB' => value * 1024,
      'MB' || 'MIB' => value * 1024 * 1024,
      'GB' || 'GIB' => value * 1024 * 1024 * 1024,
      'TB' || 'TIB' => value * 1024 * 1024 * 1024 * 1024,
      _ => 0,
    };
  }
}
