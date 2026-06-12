import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/api_client.dart';

class QueueScreen extends StatefulWidget {
  final bool embedded;
  const QueueScreen({super.key, this.embedded = false});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<dynamic> _queueItems = [];
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQueueData();
    // Poll the active queue every 1.5 seconds for progress updates
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _fetchQueueData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQueueData() async {
    final list = await ApiClient.fetchQueue();
    if (mounted) {
      setState(() {
        _queueItems = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePauseResume(Map<String, dynamic> item) async {
    final int id = item['id'] as int;
    final String status = item['status'] as String;
    
    bool success;
    if (status == 'downloading') {
      success = await ApiClient.pauseDownload(id);
    } else {
      success = await ApiClient.resumeDownload(id);
    }
    
    if (success) {
      _fetchQueueData();
    }
  }

  Future<void> _deleteItem(int id) async {
    final success = await ApiClient.deleteDownload(id);
    if (success) {
      _fetchQueueData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download canceled and removed')),
        );
      }
    }
  }

  String _getFileSizeDisplay(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Loading size...';
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Widget _buildQueueHeader() {
    final int downloadingCount = _queueItems.where((item) => (item['status'] as String? ?? '') == 'downloading').length;
    final int totalCount = _queueItems.length;

    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Queue',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              downloadingCount > 0
                  ? '$downloadingCount video${downloadingCount > 1 ? 's' : ''} downloading now'
                  : 'No active downloads currently',
              style: const TextStyle(fontSize: 12, color: MskColors.textLight),
            ),
            const SizedBox(height: 4),
            Text(
              'Total queued: $totalCount',
              style: const TextStyle(fontSize: 12, color: MskColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator(color: MskColors.secondary))
        : _queueItems.isEmpty
            ? _buildEmptyState()
            : _buildQueueList();

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Queue'),
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
            Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Queue is Empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste and analyze a YouTube link on the Home page to start downloading.',
              style: TextStyle(fontSize: 13, color: MskColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _queueItems.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildQueueHeader();
        }
        final item = _queueItems[index - 1] as Map<String, dynamic>;
        final int id = item['id'] as int;
        final String title = item['title'] as String? ?? 'YouTube Video';
        final String status = item['status'] as String? ?? 'queued';
        final double progress = (item['progress'] as num? ?? 0.0).toDouble();
        final String speed = item['download_speed'] as String? ?? '';
        final String eta = item['eta'] as String? ?? '';
        final String format = (item['format'] as String? ?? 'mp4').toUpperCase();
        final String quality = item['quality'] as String? ?? 'best';
        final int? size = item['file_size'] as int?;

        final isDownloading = status == 'downloading';
        final isPaused = status == 'paused';
        final isMerging = status == 'merging';

        Color statusColor = Colors.grey;
        String statusLabel = 'Queued';
        if (isDownloading) {
          statusColor = MskColors.secondary;
          statusLabel = 'Downloading';
        } else if (isPaused) {
          statusColor = Colors.blueGrey;
          statusLabel = 'Paused';
        } else if (isMerging) {
          statusColor = Colors.teal;
          statusLabel = 'Processing...';
        }

        return Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Meta Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: MskColors.textDark, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$quality ($format)  |  ${_getFileSizeDisplay(size)}',
                                style: const TextStyle(color: MskColors.textLight, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Actions: Pause/Resume, Delete
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDownloading || isPaused)
                          IconButton(
                            icon: Icon(isDownloading ? Icons.pause_circle_filled : Icons.play_circle_filled),
                            color: MskColors.primary,
                            iconSize: 28,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _togglePauseResume(item),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          color: MskColors.accent,
                          iconSize: 26,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteItem(id),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Download parameters (Speed, ETA, Percent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDownloading ? 'Speed: $speed' : '',
                      style: const TextStyle(color: MskColors.textLight, fontSize: 11),
                    ),
                    Text(
                      isDownloading ? 'ETA: $eta' : '',
                      style: const TextStyle(color: MskColors.textLight, fontSize: 11),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                if (isDownloading && size != null && size > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Downloaded: ${(progress / 100 * size / (1024 * 1024)).toStringAsFixed(1)} MB / ${_getFileSizeDisplay(size)}',
                    style: const TextStyle(color: MskColors.textLight, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
