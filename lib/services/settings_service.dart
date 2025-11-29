import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;
  
  // Appearance
  bool _isDarkMode = false;
  bool _autoDayNight = true;  // Auto day/night shift
  bool _blueLightFilter = true;
  String _readerFont = 'Charter';
  
  // Search & Navigation
  String _searchEngine = 'DuckDuckGo';
  bool _desktopMode = false;
  bool _enableJavascript = true;
  
  // Privacy
  bool _blockAds = true;
  bool _blockTrackers = true;
  bool _blockCookieBanners = true;
  bool _clearDataOnExit = false;
  
  // Kid Mode
  bool _kidModeEnabled = false;
  String _kidModePin = '1234';
  List<String> _kidModeWhitelist = [
    'youtubekids.com',
    'pbskids.org',
    'nickjr.com',
    'disney.com',
    'abcmouse.com',
  ];
  
  // BYOC Sync (Bring Your Own Cloud)
  bool _syncEnabled = false;
  String _syncProvider = 'none'; // 'none', 'gdrive', 'icloud', 'dropbox'
  DateTime? _lastSyncTime;
  
  // Translation
  String _preferredLanguage = 'en';
  String _portugueseVariant = 'pt-PT'; // pt-PT or pt-BR
  
  // PWA / App-ification
  List<String> _installedPWAs = [];
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get autoDayNight => _autoDayNight;
  bool get blueLightFilter => _blueLightFilter;
  String get readerFont => _readerFont;
  String get searchEngine => _searchEngine;
  bool get desktopMode => _desktopMode;
  bool get enableJavascript => _enableJavascript;
  bool get blockAds => _blockAds;
  bool get blockTrackers => _blockTrackers;
  bool get blockCookieBanners => _blockCookieBanners;
  bool get clearDataOnExit => _clearDataOnExit;
  bool get kidModeEnabled => _kidModeEnabled;
  String get kidModePin => _kidModePin;
  List<String> get kidModeWhitelist => _kidModeWhitelist;
  bool get syncEnabled => _syncEnabled;
  String get syncProvider => _syncProvider;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get preferredLanguage => _preferredLanguage;
  String get portugueseVariant => _portugueseVariant;
  List<String> get installedPWAs => _installedPWAs;
  
  String get searchUrl {
    switch (_searchEngine) {
      case 'Google':
        return 'https://www.google.com/search?q=';
      case 'Bing':
        return 'https://www.bing.com/search?q=';
      case 'DuckDuckGo':
        return 'https://duckduckgo.com/?q=';
      case 'Brave':
        return 'https://search.brave.com/search?q=';
      case 'Ecosia':
        return 'https://www.ecosia.org/search?q=';
      default:
        return 'https://duckduckgo.com/?q=';
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _autoDayNight = _prefs.getBool('autoDayNight') ?? true;
    _blueLightFilter = _prefs.getBool('blueLightFilter') ?? true;
    _readerFont = _prefs.getString('readerFont') ?? 'Charter';
    _searchEngine = _prefs.getString('searchEngine') ?? 'DuckDuckGo';
    _desktopMode = _prefs.getBool('desktopMode') ?? false;
    _enableJavascript = _prefs.getBool('enableJavascript') ?? true;
    _blockAds = _prefs.getBool('blockAds') ?? true;
    _blockTrackers = _prefs.getBool('blockTrackers') ?? true;
    _blockCookieBanners = _prefs.getBool('blockCookieBanners') ?? true;
    _clearDataOnExit = _prefs.getBool('clearDataOnExit') ?? false;
    _kidModeEnabled = _prefs.getBool('kidModeEnabled') ?? false;
    _kidModePin = _prefs.getString('kidModePin') ?? '1234';
    _kidModeWhitelist = _prefs.getStringList('kidModeWhitelist') ?? [
      'youtubekids.com',
      'pbskids.org',
      'nickjr.com',
      'disney.com',
      'abcmouse.com',
    ];
    _syncEnabled = _prefs.getBool('syncEnabled') ?? false;
    _syncProvider = _prefs.getString('syncProvider') ?? 'none';
    final lastSyncMs = _prefs.getInt('lastSyncTime');
    _lastSyncTime = lastSyncMs != null ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs) : null;
    _preferredLanguage = _prefs.getString('preferredLanguage') ?? 'en';
    _portugueseVariant = _prefs.getString('portugueseVariant') ?? 'pt-PT';
    _installedPWAs = _prefs.getStringList('installedPWAs') ?? [];
    notifyListeners();
  }

  // Setters with persistence
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setAutoDayNight(bool value) async {
    _autoDayNight = value;
    await _prefs.setBool('autoDayNight', value);
    notifyListeners();
  }

  Future<void> setBlueLightFilter(bool value) async {
    _blueLightFilter = value;
    await _prefs.setBool('blueLightFilter', value);
    notifyListeners();
  }

  Future<void> setReaderFont(String value) async {
    _readerFont = value;
    await _prefs.setString('readerFont', value);
    notifyListeners();
  }

  Future<void> setSearchEngine(String value) async {
    _searchEngine = value;
    await _prefs.setString('searchEngine', value);
    notifyListeners();
  }

  Future<void> setDesktopMode(bool value) async {
    _desktopMode = value;
    await _prefs.setBool('desktopMode', value);
    notifyListeners();
  }

  Future<void> setEnableJavascript(bool value) async {
    _enableJavascript = value;
    await _prefs.setBool('enableJavascript', value);
    notifyListeners();
  }

  Future<void> setBlockAds(bool value) async {
    _blockAds = value;
    await _prefs.setBool('blockAds', value);
    notifyListeners();
  }

  Future<void> setBlockTrackers(bool value) async {
    _blockTrackers = value;
    await _prefs.setBool('blockTrackers', value);
    notifyListeners();
  }

  Future<void> setBlockCookieBanners(bool value) async {
    _blockCookieBanners = value;
    await _prefs.setBool('blockCookieBanners', value);
    notifyListeners();
  }

  Future<void> setClearDataOnExit(bool value) async {
    _clearDataOnExit = value;
    await _prefs.setBool('clearDataOnExit', value);
    notifyListeners();
  }

  Future<void> setKidModeEnabled(bool value) async {
    _kidModeEnabled = value;
    await _prefs.setBool('kidModeEnabled', value);
    notifyListeners();
  }

  Future<void> setKidModePin(String value) async {
    _kidModePin = value;
    await _prefs.setString('kidModePin', value);
    notifyListeners();
  }

  Future<void> setKidModeWhitelist(List<String> value) async {
    _kidModeWhitelist = value;
    await _prefs.setStringList('kidModeWhitelist', value);
    notifyListeners();
  }

  Future<void> addKidModeSite(String site) async {
    if (!_kidModeWhitelist.contains(site)) {
      _kidModeWhitelist.add(site);
      await _prefs.setStringList('kidModeWhitelist', _kidModeWhitelist);
      notifyListeners();
    }
  }

  Future<void> removeKidModeSite(String site) async {
    _kidModeWhitelist.remove(site);
    await _prefs.setStringList('kidModeWhitelist', _kidModeWhitelist);
    notifyListeners();
  }

  Future<void> setSyncEnabled(bool value) async {
    _syncEnabled = value;
    await _prefs.setBool('syncEnabled', value);
    notifyListeners();
  }

  Future<void> setSyncProvider(String value) async {
    _syncProvider = value;
    await _prefs.setString('syncProvider', value);
    notifyListeners();
  }

  Future<void> updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    await _prefs.setInt('lastSyncTime', _lastSyncTime!.millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> setPreferredLanguage(String value) async {
    _preferredLanguage = value;
    await _prefs.setString('preferredLanguage', value);
    notifyListeners();
  }

  Future<void> setPortugueseVariant(String value) async {
    _portugueseVariant = value;
    await _prefs.setString('portugueseVariant', value);
    notifyListeners();
  }

  Future<void> addInstalledPWA(String url) async {
    if (!_installedPWAs.contains(url)) {
      _installedPWAs.add(url);
      await _prefs.setStringList('installedPWAs', _installedPWAs);
      notifyListeners();
    }
  }

  Future<void> removeInstalledPWA(String url) async {
    _installedPWAs.remove(url);
    await _prefs.setStringList('installedPWAs', _installedPWAs);
    notifyListeners();
  }

  bool isPWAInstalled(String url) {
    return _installedPWAs.any((pwa) => url.contains(pwa) || pwa.contains(url));
  }
}
