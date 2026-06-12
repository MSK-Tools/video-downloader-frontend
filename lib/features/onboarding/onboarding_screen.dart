import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/hive_db.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    const OnboardingSlide(
      icon: Icons.youtube_searched_for_rounded,
      title: 'Smart URL Analyzer',
      description: 'Copy and analyze YouTube, Shorts, or shared video links instantly. Check resolutions and sizes before downloading.',
    ),
    const OnboardingSlide(
      icon: Icons.music_note_rounded,
      title: 'Extract & Play Audio',
      description: 'Convert videos to high-quality audio files. Features a built-in player with picture-in-picture and background playback.',
    ),
    const OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'Creator AI Toolkit',
      description: 'Generate subtitles, detailed video transcripts, summaries, and trending titles/hashtags to elevate your workflow.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _slides[index];
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? MskColors.secondary : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next / Done Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(_currentPage == _slides.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeOnboarding() async {
    await HiveDb.setOnboardingCompleted(true);
    if (mounted) {
      context.go('/');
    }
  }
}

class OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: MskColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: MskColors.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: MskColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: MskColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
