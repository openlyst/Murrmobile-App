import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/murrtube_api.dart';
import '../utils/cookie_loader.dart';

class CookieSetupPage extends StatefulWidget {
  const CookieSetupPage({super.key});

  @override
  State<CookieSetupPage> createState() => _CookieSetupPageState();
}

class _CookieSetupPageState extends State<CookieSetupPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAssetCookie();
  }

  Future<void> _loadAssetCookie() async {
    try {
      final asset = await rootBundle.loadString('assets/cookies.txt');
      if (asset.trim().isNotEmpty && !asset.contains('Place your')) {
        final parsed = CookieLoader.parse(asset);
        _controller.text = parsed ?? asset.trim();
      }
    } catch (e) {
      debugPrint('_loadAssetCookie error: $e');
    }
  }

  Future<void> _saveAndProceed() async {
    final cookies = _controller.text.trim();
    if (cookies.isEmpty) {
      _continueAsGuest();
      return;
    }
    setState(() => _loading = true);
    MurrtubeApi.setCookies(cookies);
    await CookieLoader.save(cookies);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _continueAsGuest() {
    MurrtubeApi.clearCookies();
    CookieLoader.clear();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Murrmobile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste your browser cookies to log in, or continue as a guest to browse.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cookie String',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          '_murrtube_v3_session=...; age_check=...',
                      hintStyle:
                          TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveAndProceed,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Connect'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _continueAsGuest,
                child: const Text('Continue as Guest'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
