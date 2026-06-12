import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/murrtube_api.dart';
import '../utils/cookie_loader.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _sessionController = TextEditingController();
  final _ageCheckController = TextEditingController();
  final _xsrfController = TextEditingController();
  final _sessionIdController = TextEditingController();
  bool _loading = false;

  Future<void> _openBrowser() async {
    final uri = Uri.parse('https://murrtube.net/sign_in');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveCookies() async {
    final session = _sessionController.text.trim();
    if (session.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session cookie is required')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      String decode(String v) {
        try {
          return Uri.decodeComponent(v);
        } catch (_) {
          return v;
        }
      }

      debugPrint('=== LoginPage: _saveCookies ===');
      debugPrint('Raw session: "${session.substring(0, session.length.clamp(0, 40))}..."');

      final decodedSession = decode(session);
      debugPrint('Decoded session: "${decodedSession.substring(0, decodedSession.length.clamp(0, 40))}..."');

      final parts = <String>[
        '_murrtube_v3_session=$decodedSession',
      ];
      final ageCheck = _ageCheckController.text.trim();
      if (ageCheck.isNotEmpty) {
        final d = decode(ageCheck);
        parts.add('age_check=$d');
        debugPrint('age_check present, decoded length: ${d.length}');
      } else {
        debugPrint('age_check: empty');
      }
      final xsrf = _xsrfController.text.trim();
      if (xsrf.isNotEmpty) {
        final d = decode(xsrf);
        parts.add('XSRF-TOKEN=$d');
        debugPrint('XSRF-TOKEN present, decoded length: ${d.length}');
      } else {
        debugPrint('XSRF-TOKEN: empty');
      }
      final sessionId = _sessionIdController.text.trim();
      if (sessionId.isNotEmpty) {
        final d = decode(sessionId);
        parts.add('session_id=$d');
        debugPrint('session_id present, decoded length: ${d.length}');
      } else {
        debugPrint('session_id: empty');
      }

      final cookieString = parts.join('; ');
      debugPrint('Final cookieString length: ${cookieString.length}');
      debugPrint('Final cookieString preview: ${cookieString.substring(0, cookieString.length.clamp(0, 120))}');

      MurrtubeApi.setCookies(cookieString);
      debugPrint('Cookies set on MurrtubeApi');

      await CookieLoader.save(cookieString);
      debugPrint('Cookies saved to disk');

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, st) {
      debugPrint('LoginPage save error: $e');
      debugPrint('Stack: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildCookieField({
    required String label,
    required String cookieName,
    required TextEditingController controller,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cookieName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['monospace'],
                  ),
                ),
              ),
              if (required) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'REQUIRED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.error,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 10),
          StatefulBuilder(
            builder: (context, setLocalState) {
              return TextField(
                controller: controller,
                onChanged: (_) => setLocalState(() {}),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontFamilyFallback: ['monospace'],
                ),
                decoration: InputDecoration(
                  hintText: 'Paste value here...',
                  hintStyle: TextStyle(color: mutedColor),
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 16,
                            color: mutedColor,
                          ),
                          onPressed: () {
                            controller.clear();
                            setLocalState(() {});
                          },
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                      Icons.close,
                      size: 18,
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
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.login,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Log in to Murrtube',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Murrtube uses Telegram for authentication. Open the site in your browser, log in, then paste each cookie value into the fields below.',
              style: TextStyle(
                fontSize: 15,
                color: mutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openBrowser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_browser, size: 20),
                    SizedBox(width: 8),
                    Text('Open murrtube.net/sign_in'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _buildCookieField(
              label:
                  'This is your session token. Found in your browser cookies after logging in.',
              cookieName: '_murrtube_v3_session',
              controller: _sessionController,
              required: true,
            ),
            _buildCookieField(
              label:
                  'Verifies age check. Required to view content.',
              cookieName: 'age_check',
              controller: _ageCheckController,
              required: true,
            ),
            _buildCookieField(
              label:
                  'Security token. Needed for likes, comments, and uploads.',
              cookieName: 'XSRF-TOKEN',
              controller: _xsrfController,
              required: false,
            ),
            _buildCookieField(
              label:
                  'Session identifier. Some requests may need this.',
              cookieName: 'session_id',
              controller: _sessionIdController,
              required: false,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveCookies,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save & Connect'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Tip: In your browser\'s cookie manager, copy the "Value" for each cookie name above.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: mutedColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
