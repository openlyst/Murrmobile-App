import 'package:flutter/material.dart';
import 'services/murrtube_api.dart';
import 'utils/cookie_loader.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_shell.dart';
import 'pages/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cookies = await CookieLoader.load();
  if (cookies != null && cookies.isNotEmpty) {
    MurrtubeApi.setCookies(cookies);
  }
  runApp(const MurrtubeApp());
}

class MurrtubeApp extends StatelessWidget {
  const MurrtubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Murrmobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ResponsiveShell(),
      routes: {
        '/about/terms': (_) => const AboutPage(type: 'terms'),
        '/about/privacy': (_) => const AboutPage(type: 'privacy'),
        '/about/cookies': (_) => const AboutPage(type: 'cookies'),
        '/about/whats-new': (_) => const AboutPage(type: 'whats-new'),
      },
    );
  }
}
