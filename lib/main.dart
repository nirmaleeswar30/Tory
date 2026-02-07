import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/favorites_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent status bar + dark nav bar to match the theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF12121F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialise persistent storage.
  final storage = StorageService();
  await storage.init();

  // Bootstrap providers.
  final settingsProvider = SettingsProvider(storage);
  settingsProvider.load();

  final favoritesProvider = FavoritesProvider(storage);
  favoritesProvider.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<FavoritesProvider>.value(
          value: favoritesProvider,
        ),
        ChangeNotifierProvider<SearchProvider>(create: (_) => SearchProvider()),
      ],
      child: const ToryApp(),
    ),
  );
}
