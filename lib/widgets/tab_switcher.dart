import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tab_manager.dart';
import '../services/bookmark_service.dart';
import '../services/history_service.dart';

class TabSwitcher extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String?) onSelectUrl;

  const TabSwitcher({
    super.key,
    required this.onClose,
    required this.onSelectUrl,
  });

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = context.watch<TabManager>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: tabManager.isIncognitoMode 
        ? theme.colorScheme.surfaceContainerHighest
        : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
        title: Text(tabManager.isIncognitoMode ? 'Incognito Tabs' : 'Tabs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              tabManager.createTab();
              widget.onClose();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tabs'),
            Tab(text: 'Bookmarks'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabsGrid(tabManager),
          _buildQuickBookmarks(),
          _buildQuickHistory(),
        ],
      ),
    );
  }

  Widget _buildTabsGrid(TabManager tabManager) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: tabManager.tabs.length,
      itemBuilder: (context, index) {
        final tab = tabManager.tabs[index];
        final isSelected = index == tabManager.currentIndex;

        return GestureDetector(
          onTap: () {
            tabManager.switchToTab(index);
            widget.onClose();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      if (tab.isIncognito)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.visibility_off, size: 14),
                        ),
                      Expanded(
                        child: Text(
                          tab.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => tabManager.closeTab(index),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
                
                // Preview area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tab.isIncognito ? Icons.visibility_off : Icons.web,
                            size: 32,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              Uri.tryParse(tab.url)?.host ?? tab.url,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickBookmarks() {
    final bookmarks = context.watch<BookmarkService>();
    
    if (bookmarks.bookmarks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No bookmarks yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks.bookmarks[index];
        return ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(bookmark.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(bookmark.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => widget.onSelectUrl(bookmark.url),
        );
      },
    );
  }

  Widget _buildQuickHistory() {
    final history = context.watch<HistoryService>();
    
    if (history.history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No history yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: history.history.length.clamp(0, 20),
      itemBuilder: (context, index) {
        final entry = history.history[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(entry.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => widget.onSelectUrl(entry.url),
        );
      },
    );
  }
}
