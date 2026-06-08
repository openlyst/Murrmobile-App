import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/murrtube_api.dart';
import '../utils/cookie_loader.dart';
import 'home_page.dart';

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
        _controller.text = asset.trim();
      }
    } catch (_) {}
  }

  Future<void> _saveAndProceed() async {
    final cookies = _controller.text.trim();
    if (cookies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your cookies')),
      );
      return;
    }
    setState(() => _loading = true);
    MurrtubeApi.setCookies(cookies);
    await CookieLoader.save(cookies);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Murrtube Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your Murrtube cookies below to log in.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can extract cookies from your browser using developer tools or extensions.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Cookie String',
                hintText: '_murrtube_v3_session=...; age_check=...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveAndProceed,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
