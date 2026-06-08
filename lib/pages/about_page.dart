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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    return Scaffold(
      body: _loading
          ? Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
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
                    const SizedBox(width: 16),
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_props?['effective_date'] != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: mutedColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Effective ${_props!['effective_date']}',
                              style: TextStyle(
                                color: mutedColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Content loaded from Murrtube. For the full text, visit the website.',
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
