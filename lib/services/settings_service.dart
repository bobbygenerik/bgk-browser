import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SearchEngine { google, duckduckgo, bing, yahoo }

class SettingsService extends ChangeNotifier {
  SharedPreferences? _prefs;
  
  bool _isDarkMode = false;
  SearchEngine _searchEngine = SearchEngine.google;
  bool _blockAds = false;
  bool _blockPopups = true;
  bool _enableJavascript = true;
  bool _savePasswords = true;
  bool _doNotTrack = true;
  double _textScale = 1.0;
  String _homepage = 'https://www.google.com';
  bool _desktopMode = false;

  bool get isDarkMode => _isDarkMode;
  SearchEngine get searchEngine => _searchEngine;
  bool get blockAds => _blockAds;
  bool get blockPopups => _blockPopups;
  bool get enableJavascript => _enableJavascript;
  bool get savePasswords => _savePasswords;
  bool get doNotTrack => _doNotTrack;
  double get textScale => _textScale;
  String get homepage => _homepage;
  bool get desktopMode => _desktopMode;

  String get searchUrl {
    switch (_searchEngine) {
      case SearchEngine.google:
        return 'https://www.google.com/search?q=';
      case SearchEngine.duckduckgo:
        return 'https://duckduckgo.com/?q=';
      case SearchEngine.bing:
        return 'https://www.bing.com/search?q=';
      case SearchEngine.yahoo:
        return 'https://search.yahoo.com/search?p=';
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;
    
    _isDarkMode = _prefs!.getBool('isDarkMode') ?? false;
    _searchEngine = SearchEngine.values[_prefs!.getInt('searchEngine') ?? 0];
    _blockAds = _prefs!.getBool('blockAds') ?? false;
    _blockPopups = _prefs!.getBool('blockPopups') ?? true;
    _enableJavascript = _prefs!.getBool('enableJavascript') ?? true;
    _savePasswords = _prefs!.getBool('savePasswords') ?? true;
    _doNotTrack = _prefs!.getBool('doNotTrack') ?? true;
    _textScale = _prefs!.getDouble('textScale') ?? 1.0;
    _homepage = _prefs!.getString('homepage') ?? 'https://www.google.com';
    _desktopMode = _prefs!.getBool('desktopMode') ?? false;
    
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _prefs?.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setSearchEngine(SearchEngine engine) async {
    _searchEngine = engine;
    await _prefs?.setInt('searchEngine', engine.index);
    notifyListeners();
  }

  Future<void> setBlockAds(bool value) async {
    _blockAds = value;
    await _prefs?.setBool('blockAds', value);
    notifyListeners();
  }

  Future<void> setBlockPopups(bool value) async {
    _blockPopups = value;
    await _prefs?.setBool('blockPopups', value);
    notifyListeners();
  }

  Future<void> setEnableJavascript(bool value) async {
    _enableJavascript = value;
    await _prefs?.setBool('enableJavascript', value);
    notifyListeners();
  }

  Future<void> setSavePasswords(bool value) async {
    _savePasswords = value;
    await _prefs?.setBool('savePasswords', value);
    notifyListeners();
  }

  Future<void> setDoNotTrack(bool value) async {
    _doNotTrack = value;
    await _prefs?.setBool('doNotTrack', value);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    await _prefs?.setDouble('textScale', value);
    notifyListeners();
  }

  Future<void> setHomepage(String value) async {
    _homepage = value;
    await _prefs?.setString('homepage', value);
    notifyListeners();
  }

  Future<void> setDesktopMode(bool value) async {
    _desktopMode = value;
    await _prefs?.setBool('desktopMode', value);
    notifyListeners();
  }
}
