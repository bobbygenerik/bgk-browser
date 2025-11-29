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
import 'settings_screen.dart';
import 'bookmarks_screen.dart';
import 'history_screen.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final Map<String, InAppWebViewController?> _controllers = {};
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  bool _showTabSwitcher = false;
  bool _isLoading = false;
  double _progress = 0;
  String _currentUrl = 'https://www.google.com';
  String _pageTitle = '';

  // Chrome-like user agent for better compatibility with Google services
  static const String _userAgent = 
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }

  void _navigateToUrl(String input) {
    final tabManager = context.read<TabManager>();
    final tab = tabManager.currentTab;
    if (tab == null) return;

    String url = input.trim();
    if (!url.contains('.') || url.contains(' ')) {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    _controllers[tab.id]?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _urlFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = context.watch<TabManager>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (_showTabSwitcher) {
      return TabSwitcher(
        onClose: () => setState(() => _showTabSwitcher = false),
        onSelectUrl: (url) {
          setState(() => _showTabSwitcher = false);
          if (url != null) {
            final tab = tabManager.currentTab;
            if (tab != null) {
              _controllers[tab.id]?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
            }
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // WebView area
            Expanded(
              child: Stack(
                children: [
                  // WebView
                  if (tabManager.currentTab != null)
                    InAppWebView(
                      key: ValueKey(tabManager.currentTab!.id),
                      initialUrlRequest: URLRequest(
                        url: WebUri(tabManager.currentTab!.url),
                      ),
                      initialSettings: InAppWebViewSettings(
                        // Basic settings
                        javaScriptEnabled: true,
                        javaScriptCanOpenWindowsAutomatically: true,
                        
                        // User agent for Google compatibility
                        userAgent: _userAgent,
                        
                        // Allow third-party cookies for Google Sign-In
                        thirdPartyCookiesEnabled: true,
                        
                        // Support for popups (OAuth flows)
                        supportMultipleWindows: true,
                        
                        // Media settings
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        
                        // Mixed content for OAuth
                        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                        
                        // DOM storage for sign-in state
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        
                        // Allow file access
                        allowFileAccess: true,
                        allowContentAccess: true,
                        
                        // Hybrid composition for better compatibility
                        useHybridComposition: true,
                        
                        // Geolocation
                        geolocationEnabled: true,
                        
                        // Safe browsing (disable for OAuth redirects)
                        safeBrowsingEnabled: false,
                      ),
                      onWebViewCreated: (controller) {
                        _controllers[tabManager.currentTab!.id] = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          _isLoading = true;
                          _currentUrl = url?.toString() ?? '';
                        });
                      },
                      onLoadStop: (controller, url) async {
                        setState(() {
                          _isLoading = false;
                          _currentUrl = url?.toString() ?? '';
                        });
                        final title = await controller.getTitle();
                        if (title != null && mounted) {
                          setState(() => _pageTitle = title);
                          tabManager.updateTab(tabManager.currentTab!.id, title: title);
                          // Add to history
                          context.read<HistoryService>().addEntry(
                            title,
                            url?.toString() ?? '',
                          );
                        }
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() => _progress = progress / 100);
                      },
                      // Handle new window requests (OAuth popups)
                      onCreateWindow: (controller, createWindowAction) async {
                        // Load the popup URL in the same webview
                        final url = createWindowAction.request.url;
                        if (url != null) {
                          controller.loadUrl(urlRequest: URLRequest(url: url));
                        }
                        return false; // We handled it ourselves
                      },
                      // Handle navigation to OAuth URLs
                      shouldOverrideUrlLoading: (controller, navigationAction) async {
                        final url = navigationAction.request.url?.toString() ?? '';
                        
                        // Allow all Google auth related URLs
                        if (url.contains('accounts.google.com') ||
                            url.contains('oauth') ||
                            url.contains('signin') ||
                            url.contains('login') ||
                            url.contains('auth')) {
                          return NavigationActionPolicy.ALLOW;
                        }
                        
                        return NavigationActionPolicy.ALLOW;
                      },
                      // Handle permission requests
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                      onReceivedServerTrustAuthRequest: (controller, challenge) async {
                        return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED,
                        );
                      },
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public,
                            size: 64,
                            color: isDark ? Colors.white54 : Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'BGK Browser',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Loading indicator
                  if (_isLoading)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Bottom toolbar - Safari/Chrome style
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // URL Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: GestureDetector(
                      onTap: () => _showUrlEditor(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(
                              _isLoading ? Icons.pending : Icons.lock_outline,
                              size: 16,
                              color: isDark ? Colors.white60 : Colors.black45,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDomain(_currentUrl),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Navigation row
                  Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 8 + bottomPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () async {
                            final tab = tabManager.currentTab;
                            if (tab != null) {
                              final controller = _controllers[tab.id];
                              if (await controller?.canGoBack() ?? false) {
                                controller?.goBack();
                              }
                            }
                          },
                          isDark: isDark,
                        ),
                        _buildNavButton(
                          icon: Icons.arrow_forward_ios,
                          onTap: () async {
                            final tab = tabManager.currentTab;
                            if (tab != null) {
                              final controller = _controllers[tab.id];
                              if (await controller?.canGoForward() ?? false) {
                                controller?.goForward();
                              }
                            }
                          },
                          isDark: isDark,
                        ),
                        _buildNavButton(
                          icon: Icons.ios_share,
                          onTap: () {
                            Share.share(_currentUrl);
                          },
                          isDark: isDark,
                        ),
                        _buildNavButton(
                          icon: Icons.bookmark_outline,
                          onTap: () async {
                            final result = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BookmarksScreen(),
                              ),
                            );
                            if (result != null) {
                              final tab = tabManager.currentTab;
                              if (tab != null) {
                                _controllers[tab.id]?.loadUrl(
                                  urlRequest: URLRequest(url: WebUri(result)),
                                );
                              }
                            }
                          },
                          isDark: isDark,
                        ),
                        // Tab count button
                        GestureDetector(
                          onTap: () => setState(() => _showTabSwitcher = true),
                          child: Container(
                            width: 44,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white70 : Colors.black54,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${tabManager.tabs.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildNavButton(
                          icon: Icons.more_horiz,
                          onTap: () => _showMenu(context),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  void _showUrlEditor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _urlController.text = _currentUrl;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search or enter URL',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _urlController.clear(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3A3C) : Colors.grey[100],
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (value) {
                  Navigator.pop(context);
                  _navigateToUrl(value);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final tabManager = context.read<TabManager>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick actions grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMenuAction(
                    icon: Icons.add,
                    label: 'New Tab',
                    onTap: () {
                      Navigator.pop(context);
                      tabManager.createTab();
                    },
                    isDark: isDark,
                  ),
                  _buildMenuAction(
                    icon: Icons.bookmark,
                    label: 'Bookmarks',
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookmarksScreen(),
                        ),
                      );
                      if (result != null) {
                        final tab = tabManager.currentTab;
                        if (tab != null) {
                          _controllers[tab.id]?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(result)),
                          );
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                  _buildMenuAction(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                      if (result != null) {
                        final tab = tabManager.currentTab;
                        if (tab != null) {
                          _controllers[tab.id]?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(result)),
                          );
                        }
                      }
                    },
                    isDark: isDark,
                  ),
                  _buildMenuAction(
                    icon: Icons.refresh,
                    label: 'Refresh',
                    onTap: () {
                      Navigator.pop(context);
                      final tab = tabManager.currentTab;
                      if (tab != null) {
                        _controllers[tab.id]?.reload();
                      }
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            // More options
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                _addBookmark();
              },
            ),
            ListTile(
              leading: const Icon(Icons.desktop_mac_outlined),
              title: const Text('Request Desktop Site'),
              onTap: () {
                Navigator.pop(context);
                _requestDesktopSite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.find_in_page_outlined),
              title: const Text('Find in Page'),
              onTap: () {
                Navigator.pop(context);
                _showFindInPage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Cookies'),
              onTap: () {
                Navigator.pop(context);
                _clearCookies();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3C) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addBookmark() {
    final bookmarkService = context.read<BookmarkService>();
    bookmarkService.addBookmark(Bookmark(
      title: _pageTitle.isEmpty ? _currentUrl : _pageTitle,
      url: _currentUrl,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added')),
    );
  }

  void _requestDesktopSite() {
    final tab = context.read<TabManager>().currentTab;
    if (tab == null) return;
    
    final controller = _controllers[tab.id];
    // Set desktop user agent
    controller?.setSettings(settings: InAppWebViewSettings(
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ));
    controller?.reload();
  }

  Future<void> _clearCookies() async {
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
    
    // Also clear the webview data
    final tab = context.read<TabManager>().currentTab;
    if (tab != null) {
      final controller = _controllers[tab.id];
      await controller?.clearCache();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cookies and cache cleared')),
      );
    }
  }

  void _showFindInPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final findController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: findController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Find in page...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (value) {
                    final tab = context.read<TabManager>().currentTab;
                    if (tab != null && value.isNotEmpty) {
                      _controllers[tab.id]?.findAllAsync(find: value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: () {
                  final tab = context.read<TabManager>().currentTab;
                  if (tab != null) {
                    _controllers[tab.id]?.findNext(forward: false);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () {
                  final tab = context.read<TabManager>().currentTab;
                  if (tab != null) {
                    _controllers[tab.id]?.findNext(forward: true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  final tab = context.read<TabManager>().currentTab;
                  if (tab != null) {
                    _controllers[tab.id]?.clearMatches();
                  }
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
