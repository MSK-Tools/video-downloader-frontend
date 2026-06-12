import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/hive_db.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _downloadDir = 'Default Storage';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dir = await HiveDb.getResolvedDownloadDirectory();
    setState(() {
      _downloadDir = dir;
      _isPremium = HiveDb.isPremium;
    });
  }

  Future<void> _selectDownloadDir() async {
    // File picker directory selection is not supported on web
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Folder selection is not available on web. Use mobile or desktop app.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Use native folder picker so user can pick any directory on device
    final String? selected = await FilePicker.getDirectoryPath(dialogTitle: 'Choose Download Directory');
    if (selected != null && selected.isNotEmpty) {
      await HiveDb.setDownloadDirectory(selected);
      setState(() {
        _downloadDir = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Premium Banner
        if (!_isPremium)
          _buildPremiumPromoCard()
        else
          _buildPremiumActiveCard(),
        const SizedBox(height: 20),

        // Preferences Group
        _buildSectionHeader('Preferences'),
        Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Opacity(
                opacity: kIsWeb ? 0.6 : 1.0,
                child: ListTile(
                  leading: Icon(Icons.download_rounded, color: kIsWeb ? Colors.grey : MskColors.primary),
                  title: const Text('Download Directory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_downloadDir, style: const TextStyle(fontSize: 12)),
                      if (kIsWeb)
                        const Text(
                          '(Web only - use mobile or desktop)',
                          style: TextStyle(fontSize: 10, color: Colors.orange, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kIsWeb ? Colors.grey : null),
                  onTap: kIsWeb ? null : _selectDownloadDir,
                ),
              ),
              // Concurrent downloads limit removed — app uses internal concurrency
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tools Group
        _buildSectionHeader('Utilities'),
        Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.pie_chart_rounded, color: Colors.blue),
                title: const Text('Storage Manager', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Track and clear downloaded media', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/storage'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Account Details / Actions
        _buildSectionHeader('Account'),
        Card(
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                title: const Text('About MSK Software Solutions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/about'),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: body,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: MskColors.textLight, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildPremiumPromoCard() {
    return InkWell(
      onTap: () => context.push('/premium').then((_) => _loadSettings()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MskColors.primary, Color(0xFF0F4C81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: MskColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: MskColors.secondary, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock MSK Premium Pro',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'No Ads, 4K quality downloads, faster conversions, and background playback.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MskColors.secondary, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: MskColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.stars_rounded, color: MskColors.secondary, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MSK Pro Active',
                  style: TextStyle(color: MskColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Enjoy full access to 4K resolutions and ad-free toolkit operations.',
                  style: TextStyle(color: MskColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
