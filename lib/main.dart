import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/tab_manager.dart';
import 'services/bookmark_service.dart';
import 'services/history_service.dart';
import 'services/download_service.dart';
import 'services/settings_service.dart';
import 'screens/browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final bookmarkService = BookmarkService();
  final historyService = HistoryService();
  final downloadService = DownloadService();
  final settingsService = SettingsService();
  
  await Future.wait([
    bookmarkService.init(),
    historyService.init(),
    downloadService.init(),
    settingsService.init(),
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider.value(value: bookmarkService),
        ChangeNotifierProvider.value(value: historyService),
        ChangeNotifierProvider.value(value: downloadService),
        ChangeNotifierProvider.value(value: settingsService),
      ],
      child: const BGKBrowserApp(),
    ),
  );
}

class BGKBrowserApp extends StatelessWidget {
  const BGKBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'BGK Browser',
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const BrowserScreen(),
        );
      },
    );
  }
}
