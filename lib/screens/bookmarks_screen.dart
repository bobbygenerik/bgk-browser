import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bookmark_service.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showAddFolderDialog(context, bookmarks),
          ),
        ],
      ),
      body: bookmarks.bookmarks.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No bookmarks yet'),
                SizedBox(height: 8),
                Text('Tap the bookmark icon while browsing to add one',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView(
            children: [
              // Folders
              if (bookmarks.folders.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Folders', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...bookmarks.folders.map((folder) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(folder),
                  trailing: Text('${bookmarks.getBookmarksInFolder(folder).length}'),
                  onTap: () => _showFolderContents(context, folder, bookmarks),
                )),
                const Divider(),
              ],
              
              // All bookmarks
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('All Bookmarks', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...bookmarks.bookmarks.map((bookmark) => Dismissible(
                key: Key(bookmark.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  if (bookmark.id != null) {
                    bookmarks.removeBookmark(bookmark.id!);
                  }
                },
                child: ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(bookmark.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(bookmark.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, bookmark.url),
                ),
              )),
            ],
          ),
    );
  }

  void _showFolderContents(BuildContext context, String folder, BookmarkService bookmarks) {
    final folderBookmarks = bookmarks.getBookmarksInFolder(folder);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          AppBar(
            title: Text(folder),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: folderBookmarks.isEmpty
              ? const Center(child: Text('No bookmarks in this folder'))
              : ListView.builder(
                  itemCount: folderBookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = folderBookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(bookmark.title),
                      subtitle: Text(bookmark.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context, bookmark.url);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, BookmarkService bookmarks) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                bookmarks.addFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
