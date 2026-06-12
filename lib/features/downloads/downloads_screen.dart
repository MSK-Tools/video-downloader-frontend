import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/api_client.dart';

class DownloadsScreen extends StatefulWidget {
  final bool embedded;
  const DownloadsScreen({super.key, this.embedded = false});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<dynamic> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    final list = await ApiClient.fetchHistory();
    if (mounted) {
      setState(() {
        _historyItems = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHistoryItem(int id) async {
    final success = await ApiClient.deleteDownload(id);
    if (success) {
      _fetchHistoryData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File and download record deleted')),
        );
      }
    }
  }

  void _playMedia(Map<String, dynamic> item) {
    final format = item['format'] as String? ?? 'mp4';
    final isAudio = format == 'mp3' || format == 'm4a';
    final url = item['file_url'] as String? ?? '';
    
    // Build full backend URL if relative path
    String fullMediaUrl = url;
    if (url.startsWith('/')) {
      fullMediaUrl = '${ApiClient.baseUrl}$url';
    }

    context.push(
      '/player',
      extra: {
        'title': item['title'] as String? ?? 'YouTube Media',
        'url': fullMediaUrl,
        'isAudio': isAudio,
        'thumbnail': item['thumbnail_url'] as String? ?? '',
      },
    );
  }

  String _getFileSizeDisplay(int? bytes) {
    if (bytes == null || bytes <= 0) return '0.0 MB';
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator(color: MskColors.secondary))
        : _historyItems.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Media'),
      ),
      body: body,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Downloads Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your downloaded files and audio conversions will appear here once ready.',
              style: TextStyle(fontSize: 13, color: MskColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _historyItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _historyItems[index] as Map<String, dynamic>;
        final int id = item['id'] as int;
        final String title = item['title'] as String? ?? 'YouTube Video';
        final String format = (item['format'] as String? ?? 'mp4').toUpperCase();
        final String quality = item['quality'] as String? ?? 'best';
        final int? size = item['file_size'] as int?;
        final String dateStr = item['completed_at'] as String? ?? '';
        final String thumb = item['thumbnail_url'] as String? ?? '';
        final String status = item['status'] as String? ?? '';

        final isFailed = status == 'failed';
        final isAudio = format == 'MP3' || format == 'M4A';

        return Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          child: InkWell(
            onTap: isFailed ? null : () => _playMedia(item),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail preview
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumb,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: Icon(
                              isAudio ? Icons.audiotrack : Icons.movie,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (!isFailed)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  
                  // Text fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: MskColors.textDark, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFailed
                              ? 'Failed Download'
                              : '$quality ($format)  |  ${_getFileSizeDisplay(size)}',
                          style: TextStyle(
                            color: isFailed ? MskColors.accent : MskColors.textLight,
                            fontSize: 11,
                            fontWeight: isFailed ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Downloaded: ${_formatDate(dateStr)}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: MskColors.accent,
                    iconSize: 22,
                    onPressed: () => _deleteHistoryItem(id),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
