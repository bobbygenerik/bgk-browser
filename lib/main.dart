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
  await bookmarkService.init();
  
  final historyService = HistoryService();
  await historyService.init();
  
  final settingsService = SettingsService();
  await settingsService.init();
  
  runApp(BGKBrowser(
    bookmarkService: bookmarkService,
    historyService: historyService,
    settingsService: settingsService,
  ));
}

class BGKBrowser extends StatefulWidget {
  final BookmarkService bookmarkService;
  final HistoryService historyService;
  final SettingsService settingsService;

  const BGKBrowser({
    super.key,
    required this.bookmarkService,
    required this.historyService,
    required this.settingsService,
  });

  @override
  State<BGKBrowser> createState() => _BGKBrowserState();
}

class _BGKBrowserState extends State<BGKBrowser> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabManager()),
        ChangeNotifierProvider.value(value: widget.bookmarkService),
        ChangeNotifierProvider.value(value: widget.historyService),
        ChangeNotifierProvider(create: (_) => DownloadService()),
        ChangeNotifierProvider.value(value: widget.settingsService),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          final isDayTime = _isDayTime();
          final useDarkMode = settings.autoDayNight 
              ? !isDayTime  // Auto: dark at night
              : settings.isDarkMode;
          
          // System UI overlay style
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: useDarkMode ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: useDarkMode ? Colors.black : Colors.white,
            systemNavigationBarIconBrightness: useDarkMode ? Brightness.light : Brightness.dark,
          ));
          
          return MaterialApp(
            title: 'BGK Browser',
            debugShowCheckedModeBanner: false,
            themeMode: useDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _buildLightTheme(isDayTime),
            darkTheme: _buildDarkTheme(isDayTime),
            home: const BrowserScreen(),
          );
        },
      ),
    );
  }

  bool _isDayTime() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  ThemeData _buildLightTheme(bool isDayTime) {
    // Day mode: crisp, high contrast, productivity-focused
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDayTime ? Colors.blue : Colors.indigo,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  ThemeData _buildDarkTheme(bool isDayTime) {
    // Night mode: OLED black, easy on eyes
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black, // True OLED black
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[900],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.black,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.grey[900],
      ),
    );
  }
}
