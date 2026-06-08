import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CookieLoader {
  static String? _cached;

  static String? parse(String content) {
    final pairs = <String>[];
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('\t');
      if (parts.length >= 7) {
        pairs.add('${parts[5]}=${parts[6]}');
      }
    }
    return pairs.isEmpty ? null : pairs.join('; ');
  }

  static Future<String?> load() async {
    if (_cached != null) return _cached;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/murrtube_cookies.txt');
      if (await file.exists()) {
        final content = await file.readAsString();
        _cached = parse(content) ?? content;
        return _cached;
      }
    } catch (e) {
      debugPrint('CookieLoader.load error: $e');
    }
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

  static Future<void> clear() async {
    _cached = null;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/murrtube_cookies.txt');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
