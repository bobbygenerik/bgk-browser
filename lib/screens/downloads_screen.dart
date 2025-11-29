import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/download_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (downloads.completedDownloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: downloads.clearCompleted,
            ),
        ],
      ),
      body: downloads.downloads.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No downloads yet'),
              ],
            ),
          )
        : ListView.builder(
            itemCount: downloads.downloads.length,
            itemBuilder: (context, index) {
              final download = downloads.downloads[index];
              return _buildDownloadTile(context, download, downloads);
            },
          ),
    );
  }

  Widget _buildDownloadTile(BuildContext context, Download download, DownloadService downloads) {
    return ListTile(
      leading: _getStatusIcon(download.status),
      title: Text(download.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (download.status == DownloadStatus.downloading)
            LinearProgressIndicator(value: download.progress),
          Text(_getStatusText(download)),
        ],
      ),
      trailing: _buildTrailingWidget(download, downloads),
    );
  }

  Widget _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return const Icon(Icons.hourglass_empty);
      case DownloadStatus.downloading:
        return const CircularProgressIndicator(strokeWidth: 2);
      case DownloadStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey);
    }
  }

  String _getStatusText(Download download) {
    switch (download.status) {
      case DownloadStatus.pending:
        return 'Pending...';
      case DownloadStatus.downloading:
        final received = _formatBytes(download.bytesReceived);
        final total = download.totalBytes != null 
          ? _formatBytes(download.totalBytes!) 
          : '?';
        return '$received / $total';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return download.error ?? 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget? _buildTrailingWidget(Download download, DownloadService downloads) {
    switch (download.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => downloads.cancelDownload(download.id),
        );
      case DownloadStatus.completed:
        return IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => downloads.openDownload(download),
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => downloads.removeDownload(download.id),
        );
      default:
        return null;
    }
  }
}
