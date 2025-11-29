import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HistoryEntry {
  final int? id;
  final String url;
  final String title;
  final String? favicon;
  final DateTime visitedAt;

  HistoryEntry({
    this.id,
    required this.url,
    required this.title,
    this.favicon,
    DateTime? visitedAt,
  }) : visitedAt = visitedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'visitedAt': visitedAt.millisecondsSinceEpoch,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int?,
      url: map['url'] as String,
      title: map['title'] as String,
      favicon: map['favicon'] as String?,
      visitedAt: DateTime.fromMillisecondsSinceEpoch(map['visitedAt'] as int),
    );
  }
}

class HistoryService extends ChangeNotifier {
  Database? _database;
  List<HistoryEntry> _history = [];

  List<HistoryEntry> get history => List.unmodifiable(_history);

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bgk_history.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            favicon TEXT,
            visitedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_visited ON history(visitedAt DESC)');
      },
    );

    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_database == null) return;
    final maps = await _database!.query(
      'history',
      orderBy: 'visitedAt DESC',
      limit: 500,
    );
    _history = maps.map((m) => HistoryEntry.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addEntry(String url, String title, {String? favicon}) async {
    if (_database == null) return;
    
    final entry = HistoryEntry(url: url, title: title, favicon: favicon);
    final id = await _database!.insert('history', entry.toMap()..remove('id'));
    
    _history.insert(0, HistoryEntry(
      id: id,
      url: url,
      title: title,
      favicon: favicon,
      visitedAt: entry.visitedAt,
    ));
    
    if (_history.length > 500) {
      _history = _history.sublist(0, 500);
    }
    
    notifyListeners();
  }

  Future<void> removeEntry(int id) async {
    if (_database == null) return;
    await _database!.delete('history', where: 'id = ?', whereArgs: [id]);
    _history.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    if (_database == null) return;
    await _database!.delete('history');
    _history.clear();
    notifyListeners();
  }

  List<HistoryEntry> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _history.where((e) =>
      e.url.toLowerCase().contains(lowerQuery) ||
      e.title.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Map<String, List<HistoryEntry>> getGroupedByDate() {
    final grouped = <String, List<HistoryEntry>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in _history) {
      final date = DateTime(entry.visitedAt.year, entry.visitedAt.month, entry.visitedAt.day);
      String key;
      
      if (date == today) {
        key = 'Today';
      } else if (date == yesterday) {
        key = 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        key = 'This Week';
      } else if (date.isAfter(today.subtract(const Duration(days: 30)))) {
        key = 'This Month';
      } else {
        key = 'Older';
      }
      
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    
    return grouped;
  }
}
