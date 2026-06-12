import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/api_client.dart';
import 'package:yt_downloader/services/hive_db.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    // Mimic API request and retrieve user details
    final result = await ApiClient.loginUser(
      'creator@msksoftwaresolutions.com',
      'MSK Creator',
      true,
    );
    setState(() => _isLoading = false);

    if (result.containsKey('error')) {
      _showSnackbar(result['error'] as String);
    } else {
      await HiveDb.saveUser(result);
      if (mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.loginUser(
      'guest@msksoftwaresolutions.com',
      'Guest User',
      false,
    );
    setState(() => _isLoading = false);

    if (result.containsKey('error')) {
      _showSnackbar(result['error'] as String);
    } else {
      await HiveDb.saveUser(result);
      if (mounted) {
        context.go('/');
      }
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: MskColors.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Branding Area
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MskColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome Creator',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: MskColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to sync your download history, AI notes, and unlock premium 4K quality downloads.',
                style: TextStyle(
                  fontSize: 14,
                  color: MskColors.textLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: MskColors.secondary),
                )
              else ...[
                // Google Login Button
                ElevatedButton.icon(
                  onPressed: _handleGoogleLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MskColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                // Guest Mode Button
                OutlinedButton(
                  onPressed: _handleGuestLogin,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: MskColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: MskColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // MSK branding footer
              const Text(
                'Product of MSK Software Solutions',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
