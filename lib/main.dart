import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yt_downloader/core/router/router.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/hive_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage for cache & settings
  await HiveDb.init();
  
  // Initialize Google Mobile Ads SDK for monetization
  try {
    MobileAds.instance.initialize();
  } catch (_) {}
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MSK Video Toolkit',
      debugShowCheckedModeBanner: false,
      theme: MskTheme.lightTheme,
      routerConfig: mskRouter,
    );
  }
}
