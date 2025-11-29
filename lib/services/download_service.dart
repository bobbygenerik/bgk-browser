import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

enum DownloadStatus { pending, downloading, completed, failed, cancelled }

class Download {
  final String id;
  final String url;
  final String filename;
  final String? mimeType;
  int bytesReceived;
  int? totalBytes;
  DownloadStatus status;
  String? localPath;
  DateTime startedAt;
  String? error;

  Download({
    required this.id,
    required this.url,
    required this.filename,
    this.mimeType,
    this.bytesReceived = 0,
    this.totalBytes,
    this.status = DownloadStatus.pending,
    this.localPath,
    DateTime? startedAt,
    this.error,
  }) : startedAt = startedAt ?? DateTime.now();

  double get progress {
    if (totalBytes == null || totalBytes == 0) return 0;
    return bytesReceived / totalBytes!;
  }
}

class DownloadService extends ChangeNotifier {
  final List<Download> _downloads = [];
  String? _downloadDir;

  List<Download> get downloads => List.unmodifiable(_downloads);
  List<Download> get activeDownloads => 
    _downloads.where((d) => d.status == DownloadStatus.downloading).toList();
  List<Download> get completedDownloads =>
    _downloads.where((d) => d.status == DownloadStatus.completed).toList();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _downloadDir = '${dir.path}/Downloads';
    await Directory(_downloadDir!).create(recursive: true);
  }

  Future<String> startDownload(String url, String filename, {String? mimeType}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final download = Download(
      id: id,
      url: url,
      filename: filename,
      mimeType: mimeType,
      status: DownloadStatus.downloading,
    );
    
    _downloads.insert(0, download);
    notifyListeners();

    // Start actual download
    _performDownload(download);
    
    return id;
  }

  Future<void> _performDownload(Download download) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(download.url));
      final response = await request.close();
      
      download.totalBytes = response.contentLength;
      notifyListeners();
      
      final file = File('$_downloadDir/${download.filename}');
      final sink = file.openWrite();
      
      await for (final chunk in response) {
        if (download.status == DownloadStatus.cancelled) {
          await sink.close();
          await file.delete();
          return;
        }
        
        sink.add(chunk);
        download.bytesReceived += chunk.length;
        notifyListeners();
      }
      
      await sink.close();
      download.localPath = file.path;
      download.status = DownloadStatus.completed;
      notifyListeners();
    } catch (e) {
      download.status = DownloadStatus.failed;
      download.error = e.toString();
      notifyListeners();
    }
  }

  void cancelDownload(String id) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index].status = DownloadStatus.cancelled;
      notifyListeners();
    }
  }

  void removeDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _downloads.removeWhere((d) => 
      d.status == DownloadStatus.completed || 
      d.status == DownloadStatus.cancelled ||
      d.status == DownloadStatus.failed
    );
    notifyListeners();
  }

  Future<void> openDownload(Download download) async {
    if (download.localPath == null) return;
    // Platform-specific file opening would go here
  }
}
