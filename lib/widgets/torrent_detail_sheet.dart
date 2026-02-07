import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/torrent.dart';
import '../providers/favorites_provider.dart';
import 'score_badge.dart';

class TorrentDetailSheet extends StatelessWidget {
  final Torrent torrent;

  const TorrentDetailSheet({super.key, required this.torrent});

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite(torrent);
    final sourceName =
        AppConstants.sourceDisplayNames[torrent.source] ?? torrent.source;
    final scoreColor = AppTheme.scoreColor(torrent.qualityScore);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Poster ──
              if (torrent.poster != null && torrent.poster!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    torrent.poster!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Title ──
              Text(
                torrent.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // ── Quality score bar ──
              Row(
                children: [
                  ScoreBadge(score: torrent.qualityScore, size: 52),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quality Score',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: torrent.qualityScore / 100,
                            backgroundColor: AppTheme.cardDark,
                            color: scoreColor,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppTheme.scoreLabel(torrent.qualityScore),
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Stats grid ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _statRow(
                      Icons.arrow_upward_rounded,
                      'Seeders',
                      torrent.formattedSeeders,
                      AppTheme.seeders,
                    ),
                    _divider(),
                    _statRow(
                      Icons.arrow_downward_rounded,
                      'Leechers',
                      torrent.formattedLeechers,
                      AppTheme.leechers,
                    ),
                    if (torrent.downloads > 0) ...[
                      _divider(),
                      _statRow(
                        Icons.download_rounded,
                        'Downloads',
                        torrent.formattedDownloads,
                        AppTheme.textSecondary,
                      ),
                    ],
                    _divider(),
                    _statRow(
                      Icons.storage_rounded,
                      'Size',
                      torrent.size,
                      AppTheme.textSecondary,
                    ),
                    _divider(),
                    _statRow(
                      Icons.language_rounded,
                      'Source',
                      sourceName,
                      AppTheme.textSecondary,
                    ),
                    if (torrent.category != null) ...[
                      _divider(),
                      _statRow(
                        Icons.category_rounded,
                        'Category',
                        torrent.category!,
                        AppTheme.textSecondary,
                      ),
                    ],
                    if (torrent.language != null) ...[
                      _divider(),
                      _statRow(
                        Icons.translate_rounded,
                        'Language',
                        torrent.language!,
                        AppTheme.textSecondary,
                      ),
                    ],
                    if (torrent.uploadedBy != null &&
                        torrent.uploadedBy!.isNotEmpty) ...[
                      _divider(),
                      _statRow(
                        Icons.person_rounded,
                        'Uploader',
                        torrent.uploadedBy!,
                        AppTheme.textSecondary,
                      ),
                    ],
                    if (torrent.dateUploaded != null) ...[
                      _divider(),
                      _statRow(
                        Icons.calendar_today_rounded,
                        'Uploaded',
                        torrent.dateUploaded!,
                        AppTheme.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Action buttons ──
              Row(
                children: [
                  if (torrent.magnet != null)
                    Expanded(
                      child: _actionButton(
                        context,
                        icon: Icons.copy_rounded,
                        label: 'Copy Magnet',
                        color: AppTheme.crimson,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: torrent.magnet!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Magnet link copied!'),
                              backgroundColor: AppTheme.cardDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          HapticFeedback.mediumImpact();
                        },
                      ),
                    ),
                  if (torrent.magnet != null) const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      context,
                      icon: isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: isFav ? 'Saved' : 'Save',
                      color: isFav ? AppTheme.danger : AppTheme.purple,
                      onTap: () {
                        favProvider.toggle(torrent);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ),
                ],
              ),
              if (torrent.url != null) ...[
                const SizedBox(height: 12),
                _actionButton(
                  context,
                  icon: Icons.open_in_new_rounded,
                  label: 'Open Source Page',
                  color: const Color(0xFF5DADE2),
                  onTap: () => _launchUrl(torrent.url!),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppTheme.textMuted.withValues(alpha: 0.1), height: 1);

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
