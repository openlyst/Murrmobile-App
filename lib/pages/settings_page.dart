import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/murrtube_api.dart';
import '../utils/cookie_loader.dart';
import '../utils/app_preferences.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _props;
  bool _loading = true;
  bool _wasLoggedIn = false;
  String _theme = 'dark';
  String _videoQuality = 'auto';

  @override
  void initState() {
    super.initState();
    _wasLoggedIn = MurrtubeApi.hasCookies;
    _loadLocal();
    _load();
  }

  Future<void> _loadLocal() async {
    final theme = await AppPreferences.getTheme();
    final quality = await AppPreferences.getVideoQuality();
    if (mounted) {
      setState(() {
        _theme = theme;
        _videoQuality = quality;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nowLoggedIn = MurrtubeApi.hasCookies;
    if (nowLoggedIn != _wasLoggedIn) {
      _wasLoggedIn = nowLoggedIn;
      _load();
    }
  }

  Future<void> _load() async {
    if (!MurrtubeApi.hasCookies) {
      setState(() {
        _props = null;
        _loading = false;
      });
      return;
    }
    try {
      final props = await MurrtubeApi.getSettings();
      setState(() {
        _props = props;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SettingsPage error: $e');
      setState(() {
        _props = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _props?['user'] as Map<String, dynamic>?;
    final serverThemes = _props?['themes'] as List<dynamic>? ?? [];
    final serverQuality = _props?['video_quality_options'] as List<dynamic>? ?? [];

    final themes = serverThemes.isNotEmpty
        ? serverThemes
        : [
            {'name': 'Dark', 'value': 'dark'},
            {'name': 'Light', 'value': 'light'},
            {'name': 'AMOLED', 'value': 'amoled'},
          ];
    final qualityOptions = serverQuality.isNotEmpty
        ? serverQuality
        : [
            {'label': 'Auto', 'value': 'auto'},
            {'label': '1080p', 'value': '1080p'},
            {'label': '720p', 'value': '720p'},
            {'label': '480p', 'value': '480p'},
            {'label': '360p', 'value': '360p'},
          ];

    return Scaffold(
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 24),
                if (user != null) ...[
                  _buildCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: user['avatar_url'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: user['avatar_url'],
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: AppColors.surfaceHighlight,
                                      ),
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: AppColors.textMuted,
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceHighlight,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  if (user['slug'] != null)
                                    Text(
                                      '@${user['slug']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildActionTile(
                          icon: Icons.logout,
                          label: 'Log Out',
                          iconColor: AppColors.error,
                          onTap: () async {
                            MurrtubeApi.clearCookies();
                            await CookieLoader.clear();
                            debugPrint('Logged out');
                            if (mounted) _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildCard(
                    child: _buildActionTile(
                      icon: Icons.login,
                      label: 'Log In',
                      subtitle: 'For uploads, comments, and notifications',
                      iconColor: AppColors.primary,
                      onTap: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                        );
                        if (result == true && mounted) {
                          _load();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _SectionLabel('Appearance'),
                _buildCard(
                  child: _buildActionTile(
                    icon: Icons.palette_outlined,
                    label: 'Theme',
                    subtitle: _theme[0].toUpperCase() + _theme.substring(1),
                    onTap: () => _showSelectionSheet(
                      title: 'Select Theme',
                      options: themes.map((t) {
                        final isMap = t is Map<String, dynamic>;
                        final name = isMap ? (t['name'] ?? 'Theme') : t.toString();
                        final value = isMap ? (t['value'] ?? name.toLowerCase()) : t.toString().toLowerCase();
                        return _SelectionOption(label: name, value: value);
                      }).toList(),
                      selected: _theme,
                      onSelect: (value) async {
                        await AppPreferences.setTheme(value);
                        setState(() => _theme = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionLabel('Video Quality'),
                _buildCard(
                  child: _buildActionTile(
                    icon: Icons.high_quality_outlined,
                    label: 'Preferred Quality',
                    subtitle: _videoQuality[0].toUpperCase() + _videoQuality.substring(1),
                    onTap: () => _showSelectionSheet(
                      title: 'Select Video Quality',
                      options: qualityOptions.map((q) {
                        final isMap = q is Map<String, dynamic>;
                        final label = isMap ? (q['label'] ?? q.toString()) : q.toString();
                        final value = isMap ? (q['value'] ?? label) : q.toString();
                        return _SelectionOption(label: label, value: value);
                      }).toList(),
                      selected: _videoQuality,
                      onSelect: (value) async {
                        await AppPreferences.setVideoQuality(value);
                        setState(() => _videoQuality = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionLabel('Legal - Murrtube.net'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        onTap: () => launchUrl(
                          Uri.parse('https://murrtube.net/about/terms'),
                          mode: LaunchMode.externalApplication,
                        ),
                        showDivider: true,
                      ),
                      _buildActionTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () => launchUrl(
                          Uri.parse('https://murrtube.net/about/privacy'),
                          mode: LaunchMode.externalApplication,
                        ),
                        showDivider: true,
                      ),
                      _buildActionTile(
                        icon: Icons.cookie_outlined,
                        label: 'Cookie Policy',
                        onTap: () => launchUrl(
                          Uri.parse('https://murrtube.net/about/cookies'),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: showDivider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.3),
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet({
    required String title,
    required List<_SelectionOption> options,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final opt = options[i];
                    final isActive = selected == opt.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isActive
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isActive ? AppColors.primary : AppColors.textMuted,
                      ),
                      title: Text(
                        opt.label,
                        style: TextStyle(
                          color: isActive ? AppColors.text : AppColors.textMuted,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        onSelect(opt.value);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SelectionOption {
  final String label;
  final String value;
  const _SelectionOption({required this.label, required this.value});
}
