import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/torrent.dart';
import '../providers/search_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/source_chip.dart';
import '../widgets/torrent_card.dart';
import '../widgets/torrent_detail_sheet.dart';

class SearchScreen extends StatefulWidget {
  final String initialSource;
  final String initialQuery;
  final String? altQuery;

  const SearchScreen({
    super.key,
    this.initialSource = 'all',
    this.initialQuery = '',
    this.altQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  late String _selectedSource;
  String? _altQuery;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _scrollController = ScrollController()..addListener(_onScroll);
    _selectedSource = widget.initialSource;
    _altQuery = widget.altQuery;

    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final settings = context.read<SettingsProvider>();
      context.read<SearchProvider>().loadMore(settings.apiBaseUrl);
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    final settings = context.read<SettingsProvider>();
    final storage = context.read<StorageService>();
    storage.addRecentSearch(query.trim());
    context.read<SearchProvider>().searchImmediate(
      query.trim(),
      source: _selectedSource,
      apiBaseUrl: settings.apiBaseUrl,
      altQuery: _altQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary,
                    ),
                    onPressed: () {
                      context.read<SearchProvider>().clear();
                      Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: widget.initialQuery.isEmpty,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search torrents...',
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  searchProvider.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      onChanged: (value) {
                        setState(() {});
                        final settings = context.read<SettingsProvider>();
                        searchProvider.search(
                          value,
                          apiBaseUrl: settings.apiBaseUrl,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Source filter chips ──────────────────────────────
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: AppConstants.availableSources.length,
                itemBuilder: (context, index) {
                  final source = AppConstants.availableSources[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SourceChip(
                      source: source,
                      isSelected: _selectedSource == source,
                      onTap: () {
                        setState(() => _selectedSource = source);
                        searchProvider.setSource(source);
                        if (_searchController.text.trim().isNotEmpty) {
                          _performSearch(_searchController.text);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Sort row (shown when there are results) ─────────
            if (searchProvider.results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${searchProvider.results.length} results',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    _sortChip('Score', SortBy.score, searchProvider),
                    const SizedBox(width: 6),
                    _sortChip('Seeds', SortBy.seeders, searchProvider),
                    const SizedBox(width: 6),
                    _sortChip('Latest', SortBy.latest, searchProvider),
                    const SizedBox(width: 6),
                    _sortChip('Size', SortBy.size, searchProvider),
                  ],
                ),
              ),

            // ── Results ─────────────────────────────────────────
            Expanded(child: _buildResults(searchProvider)),
          ],
        ),
      ),
    );
  }

  // ── Sort chip ──────────────────────────────────────────────────────

  Widget _sortChip(String label, SortBy sort, SearchProvider provider) {
    final isActive = provider.sortBy == sort;
    return GestureDetector(
      onTap: () {
        provider.setSortBy(sort);
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.crimson.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.crimson.withValues(alpha: 0.5)
                : AppTheme.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.crimson : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Results body ───────────────────────────────────────────────────

  Widget _buildResults(SearchProvider provider) {
    if (provider.isLoading) return const ShimmerLoader();

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => _performSearch(_searchController.text),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.results.isEmpty && provider.currentQuery.isNotEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (provider.results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 64, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'Search across 17+ torrent sources',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.results.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.crimson,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final torrent = provider.results[index];
        return _AnimatedTorrentCard(
          index: index,
          torrent: torrent,
          onTap: () => _showDetail(torrent),
        );
      },
    );
  }

  void _showDetail(Torrent torrent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TorrentDetailSheet(torrent: torrent),
    );
  }
}

// ── Staggered fade + slide animation for each result card ────────────

class _AnimatedTorrentCard extends StatefulWidget {
  final int index;
  final Torrent torrent;
  final VoidCallback onTap;

  const _AnimatedTorrentCard({
    required this.index,
    required this.torrent,
    required this.onTap,
  });

  @override
  State<_AnimatedTorrentCard> createState() => _AnimatedTorrentCardState();
}

class _AnimatedTorrentCardState extends State<_AnimatedTorrentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = (widget.index * 60).clamp(0, 400);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: TorrentCard(
          torrent: widget.torrent,
          onTap: widget.onTap,
          index: widget.index,
        ),
      ),
    );
  }
}
