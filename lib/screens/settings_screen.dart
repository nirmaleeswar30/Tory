import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../core/constants.dart';

import '../core/theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.deepNavy,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // ── API configuration ──────────────────────────────
            _sectionHeader('API CONFIGURATION'),
            const SizedBox(height: 12),
            _settingCard(
              icon: Icons.dns_rounded,
              title: 'API Base URL',
              subtitle: settings.apiBaseUrl,
              onTap: () => _editApiUrl(context, settings),
            ),
            const SizedBox(height: 12),
            _settingCard(
              icon: Icons.movie_rounded,
              title: 'TMDB API Key',
              subtitle: settings.tmdbApiKey.isNotEmpty
                  ? '${settings.tmdbApiKey.substring(0, 8)}...'
                  : 'Not set',
              onTap: () => _editTmdbKey(context, settings),
            ),
            const SizedBox(height: 24),

            // ── Preferences ────────────────────────────────────
            _sectionHeader('PREFERENCES'),
            const SizedBox(height: 12),
            _settingCard(
              icon: Icons.source_rounded,
              title: 'Default Source',
              subtitle:
                  AppConstants.sourceDisplayNames[settings.defaultSource] ??
                  settings.defaultSource,
              onTap: () => _selectDefaultSource(context, settings),
            ),
            const SizedBox(height: 24),

            // ── About ──────────────────────────────────────────
            _sectionHeader('ABOUT'),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, String>>(
              future: _getVersionInfo(),
              builder: (context, snapshot) {
                final version = snapshot.data?['version'] ?? '...';
                final build = snapshot.data?['build'] ?? '';
                final patch = snapshot.data?['patch'];

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tory',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v$version${build.isNotEmpty ? '+$build' : ''}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (patch != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.crimson.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Patch $patch',
                            style: const TextStyle(
                              color: AppTheme.crimson,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Intelligent torrent discovery with\nscoring algorithms and beautiful UI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.crimson, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────────

  void _editApiUrl(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.apiBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'API Base URL',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'https://tory-server.vercel.app'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setApiBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editTmdbKey(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.tmdbApiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'TMDB API Key',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter your TMDB v3 API key',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settings.setTmdbApiKey(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _selectDefaultSource(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        itemCount: AppConstants.availableSources.length,
        itemBuilder: (ctx, index) {
          final source = AppConstants.availableSources[index];
          final name = AppConstants.sourceDisplayNames[source] ?? source;
          final emoji = AppConstants.sourceEmojis[source] ?? '📦';
          final isSelected = settings.defaultSource == source;

          return ListTile(
            leading: Text(emoji, style: const TextStyle(fontSize: 20)),
            title: Text(
              name,
              style: TextStyle(
                color: isSelected ? AppTheme.crimson : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_rounded, color: AppTheme.crimson)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              settings.setDefaultSource(source);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  // ── Version info ─────────────────────────────────────────────────────

  static final _updater = ShorebirdUpdater();

  static Future<Map<String, String>> _getVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    final result = <String, String>{
      'version': info.version,
      'build': info.buildNumber,
    };

    try {
      if (_updater.isAvailable) {
        final patch = await _updater.readCurrentPatch();
        if (patch != null) {
          result['patch'] = patch.number.toString();
        }
      }
    } catch (_) {
      // Shorebird not available (e.g. debug build) — skip
    }

    return result;
  }
}
