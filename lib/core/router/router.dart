import 'package:go_router/go_router.dart';
import 'package:yt_downloader/services/hive_db.dart';

// Import screens (which we will create next)
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/toolkit/url_analyzer_screen.dart';
import '../../features/queue/queue_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/storage/storage_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/premium_screen.dart';
import '../../features/settings/about_screen.dart';

final GoRouter mskRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/analyzer',
      builder: (context, state) {
        final url = state.extra as String? ?? '';
        return UrlAnalyzerScreen(youtubeUrl: url);
      },
    ),
    GoRoute(
      path: '/queue',
      builder: (context, state) => const QueueScreen(),
    ),
    GoRoute(
      path: '/downloads',
      builder: (context, state) => const DownloadsScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>? ?? {};
        return PlayerScreen(
          videoTitle: params['title'] as String? ?? 'Playing Media',
          videoUrl: params['url'] as String? ?? '',
          isAudioOnly: params['isAudio'] as bool? ?? false,
          thumbnailUrl: params['thumbnail'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/storage',
      builder: (context, state) => const StorageScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
  redirect: (context, state) {
    // Basic redirect checks:
    // If not completed onboarding, send to onboarding except if they are in splash
    final location = state.matchedLocation;
    if (location == '/splash') return null;
    
    final doneOnboarding = HiveDb.isOnboardingCompleted;
    if (!doneOnboarding && location != '/onboarding') {
      return '/onboarding';
    }
    
    // If completed onboarding, take users to the home screen without requiring login.
    if (doneOnboarding && location == '/login') {
      return '/';
    }
    
    return null;
  },
);
