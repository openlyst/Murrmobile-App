import 'package:flutter/material.dart';
import '../services/murrtube_api.dart';

class AboutPage extends StatefulWidget {
  final String type;

  const AboutPage({super.key, required this.type});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Map<String, dynamic>? _props;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      Map<String, dynamic> props;
      switch (widget.type) {
        case 'terms':
          props = await MurrtubeApi.getTerms();
          break;
        case 'privacy':
          props = await MurrtubeApi.getPrivacy();
          break;
        case 'cookies':
          props = await MurrtubeApi.getCookies();
          break;
        case 'whats-new':
          props = await MurrtubeApi.getWhatsNew();
          break;
        default:
          props = {};
      }
      setState(() {
        _props = props;
        _loading = false;
      });
    } catch (e) {
      debugPrint('AboutPage error: $e');
      setState(() => _loading = false);
    }
  }

  String get _title {
    switch (widget.type) {
      case 'terms':
        return 'Terms of Service';
      case 'privacy':
        return 'Privacy Policy';
      case 'cookies':
        return 'Cookie Policy';
      case 'whats-new':
        return "What's New";
      default:
        return 'About';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_props?['effective_date'] != null)
                    Text(
                      'Effective as of: ${_props!['effective_date']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  // The raw HTML content isn't easily rendered; show a placeholder
                  const Text(
                    'Content loaded from Murrtube. For full text, visit the website.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
