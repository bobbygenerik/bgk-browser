import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/tab_manager.dart';
import '../services/bookmark_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../widgets/tab_switcher.dart';
import '../widgets/url_bar.dart';
import 'settings_screen.dart';
import 'bookmarks_screen.dart';
import 'history_screen.dart';
import 'downloads_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> with TickerProviderStateMixin {
  final Map<String, InAppWebViewController?> _controllers = {};
  final Map<String, double> _scrollPositions = {};
  bool _showTabSwitcher = false;
  bool _isFullScreen = false;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _navigateToUrl(String input) {
    final tabManager = context.read<TabManager>();
    final settings = context.read<SettingsService>();
    final tab = tabManager.currentTab;
    if (tab == null) return;

    String url = input.trim();
    
    // Check if it's a search query or URL
    if (!url.contains('.') || url.contains(' ')) {
      url = '${settings.searchUrl}${Uri.encodeComponent(url)}';
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    _controllers[tab.id]?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _urlFocusNode.unfocus();
  }

  void _onWebViewCreated(InAppWebViewController controller, String tabId) {
    _controllers[tabId] = controller;
  }

  void _onLoadStart(String tabId, WebUri? url) {
    final tabManager = context.read<TabManager>();
    tabManager.updateTab(tabId, url: url?.toString(), isLoading: true, progress: 0.0);
  }

  void _onLoadStop(String tabId, WebUri? url) async {
    final tabManager = context.read<TabManager>();
    final controller = _controllers[tabId];
    
    final title = await controller?.getTitle() ?? 'Untitled';
    final canGoBack = await controller?.canGoBack() ?? false;
    final canGoForward = await controller?.canGoForward() ?? false;
    
    tabManager.updateTab(
      tabId,
      url: url?.toString(),
      title: title,
      isLoading: false,
      progress: 1.0,
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );

    // Add to history (if not incognito)
    final tab = tabManager.tabs.firstWhere((t) => t.id == tabId);
    if (!tab.isIncognito && url != null) {
      context.read<HistoryService>().addEntry(url.toString(), title);
    }

    if (tabId == tabManager.currentTab?.id) {
      _urlController.text = url?.toString() ?? '';
    }
  }

  void _onProgressChanged(String tabId, int progress) {
    final tabManager = context.read<TabManager>();
    tabManager.updateTab(tabId, progress: progress / 100);
  }

  void _onTitleChanged(String tabId, String? title) {
    final tabManager = context.read<TabManager>();
    tabManager.updateTab(tabId, title: title ?? 'Untitled');
  }

  Widget _buildWebView(BrowserTab tab) {
    final settings = context.watch<SettingsService>();
    
    return InAppWebView(
      key: ValueKey(tab.id),
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: settings.enableJavascript,
        userAgent: settings.desktopMode 
          ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          : null,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        preferredContentMode: settings.desktopMode 
          ? UserPreferredContentMode.DESKTOP 
          : UserPreferredContentMode.MOBILE,
      ),
      onWebViewCreated: (controller) => _onWebViewCreated(controller, tab.id),
      onLoadStart: (controller, url) => _onLoadStart(tab.id, url),
      onLoadStop: (controller, url) => _onLoadStop(tab.id, url),
      onProgressChanged: (controller, progress) => _onProgressChanged(tab.id, progress),
      onTitleChanged: (controller, title) => _onTitleChanged(tab.id, title),
      onCreateWindow: (controller, createWindowAction) async {
        final url = createWindowAction.request.url?.toString();
        if (url != null) {
          context.read<TabManager>().createTab(url: url);
        }
        return false;
      },
      onDownloadStartRequest: (controller, request) async {
        // Handle download
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading: ${request.suggestedFilename ?? "file"}')),
        );
      },
    );
  }

  void _showMenu() {
    final tabManager = context.read<TabManager>();
    final bookmarks = context.read<BookmarkService>();
    final tab = tabManager.currentTab;
    final isBookmarked = tab != null && bookmarks.isBookmarked(tab.url);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tab),
              title: const Text('New Tab'),
              onTap: () {
                Navigator.pop(context);
                tabManager.createTab();
              },
            ),
            ListTile(
              leading: Icon(tabManager.isIncognitoMode ? Icons.visibility : Icons.visibility_off),
              title: Text(tabManager.isIncognitoMode ? 'Exit Incognito' : 'Incognito Mode'),
              onTap: () {
                Navigator.pop(context);
                tabManager.toggleIncognitoMode();
                if (tabManager.isIncognitoMode) {
                  tabManager.createTab(incognito: true);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              title: Text(isBookmarked ? 'Remove Bookmark' : 'Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                if (tab != null) {
                  if (isBookmarked) {
                    final bookmark = bookmarks.getBookmark(tab.url);
                    if (bookmark?.id != null) {
                      bookmarks.removeBookmark(bookmark!.id!);
                    }
                  } else {
                    bookmarks.addBookmark(Bookmark(url: tab.url, title: tab.title));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmarks),
              title: const Text('Bookmarks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const BookmarksScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Downloads'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const DownloadsScreen(),
                ));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                if (tab != null) {
                  Share.share(tab.url, subject: tab.title);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.find_in_page),
              title: const Text('Find in Page'),
              onTap: () {
                Navigator.pop(context);
                _showFindInPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.desktop_windows),
              title: const Text('Desktop Site'),
              trailing: Switch(
                value: context.read<SettingsService>().desktopMode,
                onChanged: (v) {
                  context.read<SettingsService>().setDesktopMode(v);
                  _controllers[tab?.id]?.reload();
                  Navigator.pop(context);
                },
              ),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFindInPage() {
    final tabManager = context.read<TabManager>();
    final tab = tabManager.currentTab;
    if (tab == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Find in Page'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search...'),
            onSubmitted: (value) {
              _controllers[tab.id]?.findAllAsync(find: value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controllers[tab.id]?.findNext(forward: false);
              },
              child: const Icon(Icons.arrow_upward),
            ),
            TextButton(
              onPressed: () {
                _controllers[tab.id]?.findNext(forward: true);
              },
              child: const Icon(Icons.arrow_downward),
            ),
            TextButton(
              onPressed: () {
                _controllers[tab.id]?.clearMatches();
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabManager>(
      builder: (context, tabManager, _) {
        final currentTab = tabManager.currentTab;
        
        if (_showTabSwitcher) {
          return TabSwitcher(
            onClose: () => setState(() => _showTabSwitcher = false),
            onSelectUrl: (url) {
              setState(() => _showTabSwitcher = false);
              if (url != null && currentTab != null) {
                _controllers[currentTab.id]?.loadUrl(
                  urlRequest: URLRequest(url: WebUri(url)),
                );
              }
            },
          );
        }

        if (currentTab == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Update URL bar when tab changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_urlController.text != currentTab.url && !_urlFocusNode.hasFocus) {
            _urlController.text = currentTab.url;
          }
        });

        return PopScope(
          canPop: !(currentTab.canGoBack),
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop && currentTab.canGoBack) {
              _controllers[currentTab.id]?.goBack();
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // URL Bar
                  UrlBar(
                    controller: _urlController,
                    focusNode: _urlFocusNode,
                    isLoading: currentTab.isLoading,
                    progress: currentTab.progress,
                    isSecure: currentTab.url.startsWith('https://'),
                    isIncognito: tabManager.isIncognitoMode,
                    onSubmitted: _navigateToUrl,
                    onRefresh: () => _controllers[currentTab.id]?.reload(),
                    onStop: () => _controllers[currentTab.id]?.stopLoading(),
                  ),
                  
                  // WebView
                  Expanded(
                    child: IndexedStack(
                      index: tabManager.currentIndex,
                      children: tabManager.tabs.map((tab) => _buildWebView(tab)).toList(),
                    ),
                  ),
                  
                  // Bottom Navigation
                  if (!_isFullScreen) _buildBottomBar(currentTab),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BrowserTab tab) {
    final tabManager = context.read<TabManager>();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: tab.canGoBack ? () => _controllers[tab.id]?.goBack() : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: tab.canGoForward ? () => _controllers[tab.id]?.goForward() : null,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              final homepage = context.read<SettingsService>().homepage;
              _controllers[tab.id]?.loadUrl(urlRequest: URLRequest(url: WebUri(homepage)));
            },
          ),
          // Tab counter button
          InkWell(
            onTap: () => setState(() => _showTabSwitcher = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${tabManager.tabCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMenu,
          ),
        ],
      ),
    );
  }
}
