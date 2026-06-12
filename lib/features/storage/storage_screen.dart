import 'package:flutter/material.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/api_client.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  List<dynamic> _historyItems = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = true;
  int _totalBytesUsed = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    final list = await ApiClient.fetchHistory();
    int total = 0;
    for (var item in list) {
      final size = item['file_size'] as int? ?? 0;
      total += size;
    }

    if (mounted) {
      setState(() {
        _historyItems = list;
        _totalBytesUsed = total;
        _selectedIds.clear();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Files?'),
        content: Text('This will remove ${_selectedIds.length} files from your storage permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: MskColors.accent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      for (var id in _selectedIds) {
        await ApiClient.deleteDownload(id);
      }
      _fetchHistoryData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected files deleted successfully')),
        );
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _historyItems.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var item in _historyItems) {
          _selectedIds.add(item['id'] as int);
        }
      }
    });
  }

  String _getFileSizeDisplay(int bytes) {
    final double mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Manager'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MskColors.secondary))
          : _historyItems.isEmpty
              ? _buildEmptyState()
              : _buildStorageContent(),
      bottomNavigationBar: _selectedIds.isNotEmpty ? _buildActionBottomBar() : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storage_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No files stored yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Downloaded files will show up here to help you monitor and free up space.',
              style: TextStyle(fontSize: 13, color: MskColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageContent() {
    // Simulated phone capacity: 64GB
    const int totalStorage = 64 * 1024 * 1024 * 1024;
    final double fractionUsed = _totalBytesUsed / totalStorage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Storage visual card
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toolkit Storage Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
              ),
              const SizedBox(height: 16),
              // Linear Gauge
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fractionUsed,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(MskColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MSK Downloads: ${_getFileSizeDisplay(_totalBytesUsed)}',
                    style: const TextStyle(fontSize: 12, color: MskColors.textDark, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Total Capacity: 64 GB',
                    style: TextStyle(fontSize: 12, color: MskColors.textLight),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List Header with Select All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Files (${_historyItems.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MskColors.textDark),
              ),
              TextButton.icon(
                onPressed: _toggleSelectAll,
                icon: Icon(_selectedIds.length == _historyItems.length ? Icons.deselect : Icons.select_all),
                label: Text(_selectedIds.length == _historyItems.length ? 'Deselect All' : 'Select All'),
              ),
            ],
          ),
        ),

        // Files List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _historyItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _historyItems[index] as Map<String, dynamic>;
              final int id = item['id'] as int;
              final String title = item['title'] as String? ?? '';
              final int size = item['file_size'] as int? ?? 0;
              final String format = (item['format'] as String? ?? 'mp4').toUpperCase();
              final isChecked = _selectedIds.contains(id);

              return Card(
                elevation: 0.5,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: CheckboxListTile(
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MskColors.textDark),
                  ),
                  subtitle: Text(
                    'Format: $format  |  Size: ${_getFileSizeDisplay(size)}',
                    style: const TextStyle(fontSize: 11, color: MskColors.textLight),
                  ),
                  value: isChecked,
                  activeColor: MskColors.secondary,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedIds.add(id);
                      } else {
                        _selectedIds.remove(id);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_selectedIds.length} item(s) selected',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MskColors.textDark),
          ),
          ElevatedButton.icon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MskColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
