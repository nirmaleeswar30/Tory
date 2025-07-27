// lib/main.dart (Open Magnet Links Version)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Import the new package

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) { /* ... same as before ... */
    return MaterialApp(
      title: 'Tory', debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF1a1a1a), cardColor: const Color(0xFF2c2c2c), elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white,))),
      home: const SearchScreen(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // All state and methods (_search, _resetSearch, etc.) are the same as before.
  final _titleController = TextEditingController();
  final _maxSizeController = TextEditingController();
  String _statusMessage = 'Enter a title to begin your search.';
  bool _isLoading = false;
  List<dynamic>? _foundTorrents;
  String? _posterUrl;
  bool _isAnimeCategory = false;
  bool _showSearchResults = false;

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    if (_titleController.text.isEmpty) { setState(() => _statusMessage = 'Please enter a title.'); return; }
    setState(() { _isLoading = true; _statusMessage = 'Searching for Tory\'s treasures...'; _foundTorrents = null; _posterUrl = null; });
    String? newPosterUrl; List<dynamic>? newTorrents; String status = '';
    try {
      final authority = 'tory-server.vercel.app';
      final queryParameters = { 'title': _titleController.text, 'category': _isAnimeCategory ? 'Anime' : 'Movies', 'maxSize': _maxSizeController.text };
      final url = Uri.http(authority, '/search', queryParameters);
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); newPosterUrl = data['posterUrl']; newTorrents = data['torrents'];
        if (newTorrents == null || newTorrents.isEmpty) { status = 'No torrents found with the specified filters.'; }
      } else {
        final error = jsonDecode(response.body); status = 'Error: ${error['error']}';
      }
    } catch (e) { status = 'Error: Could not connect to Tory\'s server.';
    } finally {
      setState(() { _isLoading = false; _posterUrl = newPosterUrl; _foundTorrents = newTorrents; _statusMessage = status; _showSearchResults = true; });
    }
  }

  void _resetSearch() {
    setState(() { _showSearchResults = false; _foundTorrents = null; _posterUrl = null; _statusMessage = 'Refine your search or start a new one.'; });
  }

  Widget _buildSearchControls() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., The Matrix or Jujutsu Kaisen', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      TextField(controller: _maxSizeController, decoration: const InputDecoration(labelText: 'Max Size (GB)', hintText: 'Leave blank for any size', border: OutlineInputBorder(), suffixText: 'GB'), keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      SwitchListTile(title: const Text('Search in Anime Category'), value: _isAnimeCategory, onChanged: (bool value) => setState(() => _isAnimeCategory = value), secondary: const Icon(Icons.tv), tileColor: Theme.of(context).cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _isLoading ? null : _search, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16)), child: const Text('Go')),
    ]);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tory'), centerTitle: true, actions: [ if (_showSearchResults) IconButton(icon: const Icon(Icons.search), tooltip: 'New Search', onPressed: _resetSearch) ],),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AnimatedSize(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, child: _showSearchResults ? const SizedBox.shrink() : _buildSearchControls(),),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _isLoading ? SpinKitFadingCube(color: Colors.blue.shade300, size: 40.0,) : (_showSearchResults && _foundTorrents != null && _foundTorrents!.isNotEmpty)
                        ? ResultsView(posterUrl: _posterUrl, torrents: _foundTorrents!) : Center(child: Text(_statusMessage, key: ValueKey(_statusMessage), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AnimatedListItem has no changes
class AnimatedListItem extends StatefulWidget {
  final Widget child; final int index; const AnimatedListItem({super.key, required this.child, required this.index});
  @override State<AnimatedListItem> createState() => _AnimatedListItemState();
}
class _AnimatedListItemState extends State<AnimatedListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _fadeAnimation; late Animation<Offset> _slideAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final delay = Duration(milliseconds: widget.index * 100); Future.delayed(delay, () { if (mounted) { _controller.forward(); } });
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: widget.child)); }
}

// ResultsView has no changes
class ResultsView extends StatelessWidget {
    final String? posterUrl; final List<dynamic> torrents; const ResultsView({super.key, this.posterUrl, required this.torrents});
    @override Widget build(BuildContext context) {
        return Column(children: [ if (posterUrl != null) TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 600), builder: (context, value, child) => Opacity(opacity: value, child: Transform.scale(scale: 0.9 + (value * 0.1), child: child)), child: SizedBox(height: 180, child: ClipRRect(borderRadius: BorderRadius.circular(8.0), child: CachedNetworkImage(imageUrl: posterUrl!, fit: BoxFit.contain, placeholder: (context, url) => Center(child: SpinKitFadingCube(color: Colors.blue.shade300, size: 30.0,)), errorWidget: (context, url, error) => Icon(Icons.movie, color: Colors.grey.shade700, size: 60))))), if (posterUrl != null) const SizedBox(height: 10), if (posterUrl != null) const Divider(), Expanded(child: ListView.builder(itemCount: torrents.length, itemBuilder: (context, index) => AnimatedListItem(index: index, child: TorrentResultCard(torrent: torrents[index]))))]);
    }
}


// --- THE UPDATED TorrentResultCard WIDGET ---
class TorrentResultCard extends StatelessWidget {
  final Map<String, dynamic> torrent;
  const TorrentResultCard({super.key, required this.torrent});

  // New method to handle launching the magnet link
  Future<void> _launchMagnet(BuildContext context) async {
    final magnetUri = Uri.parse(torrent['magnet']);

    if (await canLaunchUrl(magnetUri)) {
      await launchUrl(magnetUri);
    } else {
      // If no app can handle the magnet link, fall back to copying it
      await Clipboard.setData(ClipboardData(text: torrent['magnet']));
      // Show a more informative message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to open magnet link. Copied to clipboard instead!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String providerName = torrent['provider'] ?? 'Unknown Source';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SelectableText is useful for copying the title if needed
            SelectableText(torrent["title"] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Size: ${torrent["size"]}'),
              Text('Seeders: ${torrent["seeds"]}'),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Score: ${torrent["score"]}'),
              Chip(avatar: const Icon(Icons.source, size: 16), label: Text(providerName), visualDensity: VisualDensity.compact, backgroundColor: Colors.black.withOpacity(0.2)),
            ]),
            const SizedBox(height: 10),
            Center(
              // The updated button
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open Magnet'),
                onPressed: () => _launchMagnet(context), // Call our new method
              ),
            ),
          ],
        ),
      ),
    );
  }
}