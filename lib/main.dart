import 'package:flutter/material.dart';
import 'services/murrtube_api.dart';
import 'utils/cookie_loader.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/settings_page.dart';
import 'pages/upload_page.dart';
import 'pages/notifications_page.dart';
import 'pages/about_page.dart';
import 'pages/cookie_setup_page.dart';

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
    final hasCookies = MurrtubeApi.hasCookies;
    return MaterialApp(
      title: 'Murrtube',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: hasCookies ? const HomePage() : const CookieSetupPage(),
      routes: {
        '/search': (_) => const SearchPage(),
        '/settings': (_) => const SettingsPage(),
        '/upload': (_) => const UploadPage(),
        '/notifications': (_) => const NotificationsPage(),
        '/about/terms': (_) => const AboutPage(type: 'terms'),
        '/about/privacy': (_) => const AboutPage(type: 'privacy'),
        '/about/cookies': (_) => const AboutPage(type: 'cookies'),
        '/about/whats-new': (_) => const AboutPage(type: 'whats-new'),
      },
    );
  }
}
