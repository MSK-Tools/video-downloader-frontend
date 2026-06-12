import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/api_client.dart';
import 'package:yt_downloader/services/hive_db.dart';

// Import our tabs
import '../queue/queue_screen.dart';
import '../downloads/downloads_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final TextEditingController _urlController = TextEditingController();
  String _detectedClipboardUrl = '';
  int _activeQueueCount = 0;
  Timer? _queueCountTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboardForYoutubeLink();
    _refreshQueueBadge();
    _queueCountTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshQueueBadge();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueCountTimer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForYoutubeLink();
    }
  }

  Future<void> _checkClipboardForYoutubeLink() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final text = data.text!.trim();
        if (_isYoutubeUrl(text)) {
          setState(() {
            _detectedClipboardUrl = text;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() {
      _detectedClipboardUrl = '';
    });
  }

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com/watch') ||
        url.contains('youtu.be/') ||
        url.contains('youtube.com/shorts') ||
        url.contains('youtube.com/shared');
  }

  void _handleAnalyze([String? targetUrl]) {
    final url = targetUrl ?? _urlController.text.trim();
    if (url.isEmpty || !_isYoutubeUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste a valid YouTube video link'),
          backgroundColor: MskColors.accent,
        ),
      );
      return;
    }
    setState(() {
      _detectedClipboardUrl = '';
    });
    context.push('/analyzer', extra: url);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _urlController.text = data.text!;
      _handleAnalyze(data.text);
    }
  }

  Future<void> _refreshQueueBadge() async {
    final list = await ApiClient.fetchQueue();
    if (!mounted) return;
    final activeDownloads = list.where((item) => (item['status'] as String? ?? '') == 'downloading').length;
    setState(() {
      _activeQueueCount = activeDownloads;
    });
  }

  Widget _buildBottomNavIcon(IconData icon, {int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MskColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = HiveDb.currentUser ?? {};
    final isPremium = HiveDb.isPremium;

    final List<Widget> tabs = [
      _buildHomeDashboard(user, isPremium),
      const QueueScreen(embedded: true),
      const DownloadsScreen(embedded: true),
      const SettingsScreen(embedded: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill_rounded, color: MskColors.secondary),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0 ? 'MSK Video Toolkit' : 
              _currentIndex == 1 ? 'Download Queue' : 
              _currentIndex == 2 ? 'Downloads' : 'Settings',
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: isPremium
                  ? const Chip(
                      label: Text('PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      backgroundColor: MskColors.secondary,
                      padding: EdgeInsets.zero,
                    )
                  : IconButton(
                      icon: const Icon(Icons.stars_rounded, color: MskColors.secondary),
                      onPressed: () => context.push('/premium'),
                    ),
            ),
        ],
      ),
      body: Stack(
        children: [
          tabs[_currentIndex],
          if (_currentIndex == 0 && _detectedClipboardUrl.isNotEmpty)
            _buildClipboardBanner(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: MskColors.secondary,
        unselectedItemColor: MskColors.primary.withOpacity(0.6),
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildBottomNavIcon(Icons.downloading_rounded, badgeCount: _activeQueueCount),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_zip_rounded),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(Map<String, dynamic> user, bool isPremium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User welcome row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: MskColors.primary.withOpacity(0.1),
                backgroundImage: NetworkImage(user['avatar_url'] ?? ''),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user['name'] ?? 'Creator'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MskColors.textDark,
                    ),
                  ),
                  Text(
                    isPremium ? 'Premium Subscribed' : 'Free Account (Guest Mode)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPremium ? MskColors.secondary : MskColors.textLight,
                      fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Card
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Analyze YouTube URLs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MskColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Paste YouTube Video, Shorts or Share link',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded, color: MskColors.primary),
                        onPressed: _pasteFromClipboard,
                        tooltip: 'Paste from clipboard',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _handleAnalyze(),
                    child: const Text('Analyze & Process Link'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Toolkit Actions
          const Text(
            'Video Creator Toolkit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MskColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(
                icon: Icons.history_rounded,
                title: 'Download History',
                subtitle: 'View, Play & Share',
                color: MskColors.primary,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _buildActionCard(
                icon: Icons.downloading_rounded,
                title: 'Download Queue',
                subtitle: 'Pause, Resume & Track',
                color: MskColors.secondary,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _buildActionCard(
                icon: Icons.pie_chart_rounded,
                title: 'Storage Manager',
                subtitle: 'Manage local files',
                color: Colors.blue.shade700,
                onTap: () => context.push('/storage'),
              ),
              _buildActionCard(
                icon: Icons.star_purple500_rounded,
                title: 'Premium Upgrade',
                subtitle: 'Ad-Free, 4K resolution',
                color: Colors.amber.shade700,
                onTap: () => context.push('/premium'),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MskColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: MskColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipboardBanner() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        color: MskColors.primary,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'YouTube Link Detected in Clipboard!',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  _urlController.text = _detectedClipboardUrl;
                  _handleAnalyze(_detectedClipboardUrl);
                },
                style: TextButton.styleFrom(
                  foregroundColor: MskColors.secondary,
                ),
                child: const Text('Analyze'),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onPressed: () {
                  setState(() {
                    _detectedClipboardUrl = '';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
