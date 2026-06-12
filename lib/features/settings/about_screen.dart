import 'package:flutter/material.dart';
import 'package:yt_downloader/core/theme/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('About MSK'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Branding
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MskColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MSK Software Solutions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: MskColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: MskColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            const Text(
              'Company Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'MSK Software Solutions is dedicated to building state-of-the-art tools and applications for creators, engineers, and businesses. We focus on clean architectures, high-performance computing, and user-centric designs.',
              style: TextStyle(fontSize: 13, color: MskColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Core Values List
            const Text(
              'Our Values',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 12),
            _buildValueRow(Icons.security_rounded, 'Security & Compliance', 'We build compliant platforms protecting intellectual properties and respecting copyright terms.'),
            _buildValueRow(Icons.auto_awesome_mosaic_rounded, 'Clean Architectures', 'Our software codebase represents industry best-practices, scale capability, and modular structures.'),
            _buildValueRow(Icons.speed_rounded, 'Performance First', 'From local downloader speeds to AI transcript lookups, our backends deliver high performance.'),
            const SizedBox(height: 24),

            // Legal & Terms links
            const Text(
              'Contact & Support',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MskColors.textDark),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0.5,
              color: MskColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.email, color: MskColors.primary),
                    title: Text('support@msksoftwaresolutions.com', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Email Support', style: TextStyle(fontSize: 10)),
                  ),
                  Divider(height: 1, indent: 56),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.web, color: MskColors.primary),
                    title: Text('www.msksoftwaresolutions.com', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('Visit our Website', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              '© 2026 MSK Software Solutions. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MskColors.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MskColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: MskColors.textLight, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
