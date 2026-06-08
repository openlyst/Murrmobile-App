import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/murrtube_api.dart';
import '../utils/cookie_loader.dart';
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

  @override
  void initState() {
    super.initState();
    _wasLoggedIn = MurrtubeApi.hasCookies;
    _load();
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
    try {
      final props = await MurrtubeApi.getSettings();
      setState(() {
        _props = props;
        _loading = false;
      });
    } catch (e) {
      debugPrint('SettingsPage error: $e');
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
                if (themes.isNotEmpty) ...[
                  _SectionLabel('Appearance'),
                  _buildCard(
                    child: Column(
                      children: themes
                          .whereType<Map<String, dynamic>>()
                          .map((t) => _buildActionTile(
                                icon: t['active'] == true
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                label: t['name'] ?? 'Theme',
                                iconColor: t['active'] == true
                                    ? AppColors.secondary
                                    : AppColors.textMuted,
                                showDivider: t != themes.last,
                                onTap: () {},
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (qualityOptions.isNotEmpty) ...[
                  _SectionLabel('Video Quality'),
                  _buildCard(
                    child: Column(
                      children: qualityOptions
                          .whereType<Map<String, dynamic>>()
                          .map((q) => _buildActionTile(
                                icon: q['active'] == true
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                label: q['label'] ?? q.toString(),
                                iconColor: q['active'] == true
                                    ? AppColors.secondary
                                    : AppColors.textMuted,
                                showDivider: q != qualityOptions.last,
                                onTap: () {},
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _SectionLabel('Legal'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        onTap: () => Navigator.pushNamed(context, '/about/terms'),
                        showDivider: true,
                      ),
                      _buildActionTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy Policy',
                        onTap: () =>
                            Navigator.pushNamed(context, '/about/privacy'),
                        showDivider: true,
                      ),
                      _buildActionTile(
                        icon: Icons.cookie_outlined,
                        label: 'Cookie Policy',
                        onTap: () =>
                            Navigator.pushNamed(context, '/about/cookies'),
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
