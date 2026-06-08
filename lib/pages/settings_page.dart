import 'package:flutter/material.dart';
import '../services/murrtube_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _props;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final props = await MurrtubeApi.getSettings();
      setState(() {
        _props = props;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _props?['user'] as Map<String, dynamic>?;
    final themes = _props?['themes'] as List<dynamic>? ?? [];
    final qualityOptions =
        _props?['video_quality_options'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (user != null) ...[
                  ListTile(
                    leading: user['avatar_url'] != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user['avatar_url']),
                          )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['name'] ?? 'User'),
                    subtitle: Text(user['slug'] ?? ''),
                  ),
                  const Divider(),
                ],
                const ListTile(
                  title: Text('Appearance'),
                  subtitle: Text('Theme settings'),
                ),
                ...themes.map((t) => ListTile(
                      title: Text(t['name'] ?? 'Theme'),
                      trailing: t['active'] == true
                          ? const Icon(Icons.check)
                          : null,
                    )),
                const Divider(),
                const ListTile(
                  title: Text('Video Quality'),
                  subtitle: Text('Default playback quality'),
                ),
                ...qualityOptions.map((q) => ListTile(
                      title: Text(q['label'] ?? q.toString()),
                      trailing: q['active'] == true
                          ? const Icon(Icons.check)
                          : null,
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Upload Video'),
                  onTap: () => Navigator.pushNamed(context, '/upload'),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  onTap: () => Navigator.pushNamed(context, '/about/terms'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  onTap: () => Navigator.pushNamed(context, '/about/privacy'),
                ),
                ListTile(
                  leading: const Icon(Icons.cookie),
                  title: const Text('Cookie Policy'),
                  onTap: () => Navigator.pushNamed(context, '/about/cookies'),
                ),
              ],
            ),
    );
  }
}
