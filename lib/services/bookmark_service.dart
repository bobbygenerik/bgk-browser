import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Bookmark {
  final int? id;
  final String url;
  final String title;
  final String? favicon;
  final String? folder;
  final DateTime createdAt;

  Bookmark({
    this.id,
    required this.url,
    required this.title,
    this.favicon,
    this.folder,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'folder': folder,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String,
      favicon: map['favicon'] as String?,
      folder: map['folder'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}

class BookmarkService extends ChangeNotifier {
  Database? _database;
  List<Bookmark> _bookmarks = [];
  List<String> _folders = ['Favorites', 'Reading List'];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  List<String> get folders => List.unmodifiable(_folders);

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bgk_bookmarks.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookmarks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            favicon TEXT,
            folder TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE folders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        ''');
        await db.insert('folders', {'name': 'Favorites'});
        await db.insert('folders', {'name': 'Reading List'});
      },
    );

    await _loadBookmarks();
    await _loadFolders();
  }

  Future<void> _loadBookmarks() async {
    if (_database == null) return;
    final maps = await _database!.query('bookmarks', orderBy: 'createdAt DESC');
    _bookmarks = maps.map((m) => Bookmark.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> _loadFolders() async {
    if (_database == null) return;
    final maps = await _database!.query('folders');
    _folders = maps.map((m) => m['name'] as String).toList();
    notifyListeners();
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    if (_database == null) return;
    final id = await _database!.insert('bookmarks', bookmark.toMap()..remove('id'));
    _bookmarks.insert(0, Bookmark(
      id: id,
      url: bookmark.url,
      title: bookmark.title,
      favicon: bookmark.favicon,
      folder: bookmark.folder,
      createdAt: bookmark.createdAt,
    ));
    notifyListeners();
  }

  Future<void> removeBookmark(int id) async {
    if (_database == null) return;
    await _database!.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    _bookmarks.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }

  Bookmark? getBookmark(String url) {
    try {
      return _bookmarks.firstWhere((b) => b.url == url);
    } catch (_) {
      return null;
    }
  }

  List<Bookmark> getBookmarksInFolder(String? folder) {
    if (folder == null) {
      return _bookmarks.where((b) => b.folder == null).toList();
    }
    return _bookmarks.where((b) => b.folder == folder).toList();
  }

  Future<void> addFolder(String name) async {
    if (_database == null || _folders.contains(name)) return;
    await _database!.insert('folders', {'name': name});
    _folders.add(name);
    notifyListeners();
  }
}
