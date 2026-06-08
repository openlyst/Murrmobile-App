import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CookieLoader {
  static String? _cached;

  static Future<String?> load() async {
    if (_cached != null) return _cached;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/murrtube_cookies.txt');
      if (await file.exists()) {
        _cached = await file.readAsString();
        return _cached;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> save(String cookies) async {
    _cached = cookies;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/murrtube_cookies.txt');
    await file.writeAsString(cookies);
  }

  static void set(String cookies) {
    _cached = cookies;
  }
}
