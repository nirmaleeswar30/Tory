import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/torrent.dart';
import '../providers/favorites_provider.dart';
import '../widgets/torrent_card.dart';
import '../widgets/torrent_detail_sheet.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final favorites = favProvider.favorites;

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Favorites',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (favorites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  '${favorites.length} saved torrent${favorites.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: favorites.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final torrent = favorites[index];
                        return Dismissible(
                          key: Key(
                            torrent.magnet ??
                                '${torrent.name}_${torrent.source}',
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: AppTheme.danger,
                            ),
                          ),
                          onDismissed: (_) => favProvider.remove(torrent),
                          child: GestureDetector(
                            onLongPress: () {
                              if (torrent.magnet != null) {
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
                              }
                            },
                            child: TorrentCard(
                              torrent: torrent,
                              onTap: () => _showDetail(context, torrent),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: AppTheme.textMuted,
          ),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Save torrents from search results',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Torrent torrent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TorrentDetailSheet(torrent: torrent),
    );
  }
}
