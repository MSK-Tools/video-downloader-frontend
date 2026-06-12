import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:yt_downloader/services/browser_downloader.dart';
import 'package:yt_downloader/services/api_client.dart';
import 'package:yt_downloader/services/download_manager.dart';
import 'package:flutter/services.dart';

class UrlAnalyzerScreen extends StatefulWidget {
  final String youtubeUrl;
  const UrlAnalyzerScreen({super.key, required this.youtubeUrl});

  @override
  State<UrlAnalyzerScreen> createState() => _UrlAnalyzerScreenState();
}

class _UrlAnalyzerScreenState extends State<UrlAnalyzerScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _metadata = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await ApiClient.analyzeUrl(widget.youtubeUrl);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.containsKey('error')) {
          _errorMessage = result['error'] as String;
        } else {
          _metadata = result;
        }
      });
    }
  }

  Future<void> _triggerDownload(Map<String, dynamic> format) async {
    // Show quick confirmation dialog or trigger
    final formatName = format['name'] as String;
    final ext = format['ext'] as String;
    final sizeBytes = format['filesize'] as int;
    final title = _metadata['title'] as String? ?? 'YouTube Video';

    // Generate filename
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${sanitizedTitle}_$formatName.$ext';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting download for: $formatName ($ext)'),
        backgroundColor: MskColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );

    // Trigger backend to prepare/process the download
    final backendResult = await ApiClient.triggerDownload(
      url: widget.youtubeUrl,
      videoId: _metadata['video_id'] as String? ?? '',
      title: title,
      thumbnailUrl: _metadata['thumbnail_url'] as String? ?? '',
      format: ext,
      quality: formatName,
      fileSize: sizeBytes,
    );

    if (mounted) {
      if (backendResult.containsKey('error')) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${backendResult['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If backend provides a download URL, download it client-side
      final downloadUrl = backendResult['download_url'] as String?;
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        _performClientDownload(downloadUrl, fileName);
      } else {
        // Fall back to showing queue/progress on home
        print('⚠️ No download_url from backend, showing queue instead');
        context.go('/');
      }
    }
  }

  Future<void> _performClientDownload(String downloadUrl, String fileName) async {
    // For web, trigger the browser's download (saves to browser's default downloads folder)
    if (kIsWeb) {
      try {
        await triggerBrowserDownload(downloadUrl, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Download started in browser: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Browser download failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Show native progress dialog on mobile/desktop
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return DownloadProgressDialog(
          downloadUrl: downloadUrl,
          fileName: fileName,
          onComplete: () {
            if (mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Download complete: $fileName'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              // Go home
              context.go('/');
            }
          },
          onError: (error) {
            if (mounted) {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Download failed: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Unknown Size';
    final double mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;
    final int remainingSeconds = seconds % 60;

    final String secStr = remainingSeconds.toString().padLeft(2, '0');
    final String minStr = remainingMinutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:${minStr}:${secStr}';
    }
    return '${remainingMinutes}:${secStr}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Analyzer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildContentState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: MskColors.secondary),
            const SizedBox(height: 24),
            const Text(
              'Analyzing video stream...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              widget.youtubeUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: MskColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: MskColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Analysis Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 14, color: MskColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performAnalysis,
              child: const Text('Retry Analysis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState() {
    final videoFormats = _metadata['video_formats'] as List<dynamic>? ?? [];
    final audioFormats = _metadata['audio_formats'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Video overview card
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _metadata['thumbnail_url'] as String? ?? '',
                      width: 120,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.black.withOpacity(0.8),
                    child: Text(
                      _formatDuration(_metadata['duration'] as int? ?? 0),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Metadata fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _metadata['title'] as String? ?? 'Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MskColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _metadata['channel'] as String? ?? 'Channel',
                      style: const TextStyle(fontSize: 12, color: MskColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs header
        TabBar(
          controller: _tabController,
          labelColor: MskColors.primary,
          unselectedLabelColor: MskColors.textLight,
          indicatorColor: MskColors.secondary,
          tabs: const [
            Tab(text: 'Video Qualities'),
            Tab(text: 'Audio Only'),
            Tab(text: 'Creator AI Tools'),
          ],
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Video formats
              _buildFormatsList(videoFormats, isAudio: false),
              // Audio formats
              _buildFormatsList(audioFormats, isAudio: true),
              // AI tools
              _buildAiToolsSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatsList(List<dynamic> list, {required bool isAudio}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No formats available',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final f = list[index] as Map<String, dynamic>;
        final String name = f['name'] as String? ?? 'Standard';
        final String ext = f['ext'] as String? ?? 'mp4';
        final int size = f['filesize'] as int? ?? 0;

        return Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isAudio ? Icons.audiotrack_rounded : Icons.videocam_rounded,
                  color: isAudio ? Colors.teal : Colors.blue.shade700,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: MskColors.textDark, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Format: ${ext.toUpperCase()}  |  Est: ${_formatFileSize(size)}',
                        style: const TextStyle(color: MskColors.textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _triggerDownload(f),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MskColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Download'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiToolsSection() {
    final aiSummary = _metadata['ai_summary'] as String? ?? '';
    final aiTitles = _metadata['ai_titles'] as List<dynamic>? ?? [];
    final aiHashtags = _metadata['ai_hashtags'] as List<dynamic>? ?? [];
    final transcript = _metadata['transcript_sample'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Summary
          _buildToolHeader(Icons.auto_awesome_rounded, 'AI Summary Notes'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MskColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              aiSummary,
              style: const TextStyle(fontSize: 14, color: MskColors.textDark, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),

          // AI Suggestion Titles
          _buildToolHeader(Icons.lightbulb_outline_rounded, 'AI Content Ideas'),
          const SizedBox(height: 8),
          ...aiTitles.map((title) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.star_border, color: MskColors.secondary),
              title: Text(title as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: title));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied Title!')));
                },
              ),
            ),
          )),
          const SizedBox(height: 16),

          // AI Hashtags
          _buildToolHeader(Icons.tag_rounded, 'AI Tags & Hashtags'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aiHashtags.map((tag) => Chip(
              label: Text(tag as String, style: const TextStyle(fontSize: 12, color: MskColors.primary)),
              backgroundColor: MskColors.primary.withOpacity(0.05),
              deleteIcon: const Icon(Icons.copy, size: 12, color: MskColors.primary),
              onDeleted: () {
                Clipboard.setData(ClipboardData(text: tag));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied Tag!')));
              },
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Transcript
          _buildToolHeader(Icons.subtitles_rounded, 'AI Generated Transcript'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MskColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  transcript,
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: transcript));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied full transcript!')));
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy Transcript'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: MskColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
        ),
      ],
    );
  }
}

/// Dialog widget that shows download progress using the DownloadManager.
class DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  final String fileName;
  final VoidCallback onComplete;
  final Function(String) onError;

  const DownloadProgressDialog({
    super.key,
    required this.downloadUrl,
    required this.fileName,
    required this.onComplete,
    required this.onError,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0;
  String _progressText = '0 B / 0 B';
  bool _isDownloading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await DownloadManager.downloadFile(
        url: widget.downloadUrl,
        fileName: widget.fileName,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _progress = total > 0 ? received / total : 0;
              _progressText = '${_formatBytes(received)} / ${_formatBytes(total)}';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = 1.0;
        });
        Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString();
        });
        widget.onError(e.toString());
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.download_rounded, color: MskColors.secondary),
          SizedBox(width: 12),
          Text('Downloading...'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: MskColors.textLight),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(MskColors.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}% — $_progressText',
            style: const TextStyle(fontSize: 12, color: MskColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        if (!_isDownloading && _errorMessage.isEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        if (_errorMessage.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
