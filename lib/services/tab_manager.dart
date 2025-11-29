import 'package:flutter/foundation.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  bool isLoading;
  double progress;
  bool canGoBack;
  bool canGoForward;
  bool isIncognito;
  DateTime createdAt;
  DateTime lastVisited;

  BrowserTab({
    required this.id,
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.favicon,
    this.isLoading = false,
    this.progress = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isIncognito = false,
    DateTime? createdAt,
    DateTime? lastVisited,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastVisited = lastVisited ?? DateTime.now();

  BrowserTab copyWith({
    String? url,
    String? title,
    String? favicon,
    bool? isLoading,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
    DateTime? lastVisited,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isIncognito: isIncognito,
      createdAt: createdAt,
      lastVisited: lastVisited ?? this.lastVisited,
    );
  }
}

class TabManager extends ChangeNotifier {
  final List<BrowserTab> _tabs = [];
  int _currentIndex = 0;
  bool _isIncognitoMode = false;

  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  int get currentIndex => _currentIndex;
  BrowserTab? get currentTab => _tabs.isNotEmpty ? _tabs[_currentIndex] : null;
  bool get isIncognitoMode => _isIncognitoMode;
  int get tabCount => _tabs.length;

  TabManager() {
    createTab();
  }

  String createTab({String? url, bool incognito = false}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final tab = BrowserTab(
      id: id,
      url: url ?? 'https://www.google.com',
      isIncognito: incognito || _isIncognitoMode,
    );
    _tabs.add(tab);
    _currentIndex = _tabs.length - 1;
    notifyListeners();
    return id;
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) {
      createTab();
      _tabs.removeAt(index);
      _currentIndex = 0;
    } else {
      _tabs.removeAt(index);
      if (_currentIndex >= _tabs.length) {
        _currentIndex = _tabs.length - 1;
      } else if (_currentIndex > index) {
        _currentIndex--;
      }
    }
    notifyListeners();
  }

  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void updateTab(String id, {
    String? url,
    String? title,
    String? favicon,
    bool? isLoading,
    double? progress,
    bool? canGoBack,
    bool? canGoForward,
  }) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index] = _tabs[index].copyWith(
        url: url,
        title: title,
        favicon: favicon,
        isLoading: isLoading,
        progress: progress,
        canGoBack: canGoBack,
        canGoForward: canGoForward,
        lastVisited: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void toggleIncognitoMode() {
    _isIncognitoMode = !_isIncognitoMode;
    notifyListeners();
  }

  void closeAllTabs() {
    _tabs.clear();
    createTab();
    notifyListeners();
  }

  void closeOtherTabs(int keepIndex) {
    if (keepIndex < 0 || keepIndex >= _tabs.length) return;
    final tabToKeep = _tabs[keepIndex];
    _tabs.clear();
    _tabs.add(tabToKeep);
    _currentIndex = 0;
    notifyListeners();
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final tab = _tabs.removeAt(oldIndex);
    _tabs.insert(newIndex, tab);
    
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
      _currentIndex--;
    } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
      _currentIndex++;
    }
    notifyListeners();
  }
}
