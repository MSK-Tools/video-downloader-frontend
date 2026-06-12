import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yt_downloader/features/auth/login_screen.dart';
import 'package:yt_downloader/features/onboarding/onboarding_screen.dart';
import 'package:yt_downloader/features/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows branding and progress indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('MSK Video Toolkit'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_filled_rounded), findsOneWidget);
  });

  testWidgets('OnboardingScreen shows skip and next buttons and advances pages', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Smart URL Analyzer'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Next'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Next'));
    await tester.pumpAndSettle();

    expect(find.text('Extract & Play Audio'), findsOneWidget);
  });

  testWidgets('LoginScreen shows Google and guest login buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Sign In with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
  });
}
