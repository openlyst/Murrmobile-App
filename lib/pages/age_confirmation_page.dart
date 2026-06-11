import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgeConfirmationPage extends StatelessWidget {
  const AgeConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Age Verification',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This app contains adult content. You must be 18 years or older to use this app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleExit(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Exit'),
                    ),
                    ElevatedButton(
                      onPressed: () => _handleConfirm(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('I am 18+'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('age_confirmed', true);
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleExit(BuildContext context) async {
    // Exit the app - on mobile this will close the app
    // On web/desktop, we'll show a message
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      // For mobile, we can't really exit the app programmatically
      // So we'll just show a message and close the dialog
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please close the app to exit'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (context.mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }
}
