import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const baseUrl = 'https://murrtube.net';

void log(String msg) => print('[${DateTime.now().toIso8601String()}] $msg');

Future<void> main() async {
  log('=== Unauthed Video Load Test ===');
  log('No cookies, no auth. Testing full guest flow.');

  // Step 1: Hit home with Inertia headers (no version, no cookies)
  log('\n--- Step 1: First request to /?tab=trending with Inertia ---');
  final uri1 = Uri.parse('$baseUrl/?tab=trending');
  final resp1 = await http.get(uri1, headers: {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,application/json,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'X-Inertia': 'true',
    'Referer': baseUrl,
  });
  log('Status: ${resp1.statusCode}');
  log('Headers: ${resp1.headers.keys.toList()}');
  final setCookie1 = resp1.headers['set-cookie'];
  log('Set-Cookie: ${setCookie1?.substring(0, setCookie1.length.clamp(0, 200))}');

  final body1 = utf8.decode(resp1.bodyBytes);
  log('Body starts: ${body1.substring(0, body1.length.clamp(0, 200))}');

  // Step 2: If 409 or not JSON, fetch root page normally
  if (resp1.statusCode == 409 || !body1.startsWith('{')) {
    log('\n--- Step 2: Fetch root page without Inertia to get session + age check ---');
    final uri2 = Uri.parse(baseUrl);
    final resp2 = await http.get(uri2, headers: {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': baseUrl,
    });
    log('Root status: ${resp2.statusCode}');

    final setCookie2 = resp2.headers['set-cookie'];
    log('Root Set-Cookie: ${setCookie2?.substring(0, setCookie2.length.clamp(0, 300))}');

    final body2 = utf8.decode(resp2.bodyBytes);
    log('Root body length: ${body2.length}');

    // Extract CSRF token
    final csrfRegex = RegExp(r'<meta name="csrf-token" content="([^"]+)"');
    final csrfMatch = csrfRegex.firstMatch(body2);
    final csrfToken = csrfMatch?.group(1);
    log('CSRF token: ${csrfToken != null ? "found" : "NOT FOUND"}');

    // Check for age check form
    final hasAgeCheck = body2.contains('age_check') || body2.contains('age-check');
    log('Has age check: $hasAgeCheck');

    // Extract age check form action
    final actionRegex = RegExp(r'action="([^"]*age_check[^"]*)"');
    final actionMatch = actionRegex.firstMatch(body2);
    final ageAction = actionMatch?.group(1);
    log('Age check form action: $ageAction');

    // Step 3: Build cookie jar from all responses
    final jar = <String, String>{};
    for (final raw in [setCookie1, setCookie2]) {
      if (raw == null) continue;
      for (final part in raw.split(',')) {
        final c = part.split(';').first.trim();
        final i = c.indexOf('=');
        if (i != -1) jar[c.substring(0, i)] = c.substring(i + 1);
      }
    }
    final cookieStr = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
    log('Built cookie jar: ${jar.keys.toList()}');

    // Step 4: Try age check bypass with discovered action
    if (hasAgeCheck && csrfToken != null) {
      final ageUrl = ageAction != null && ageAction.startsWith('http')
          ? ageAction
          : '$baseUrl${ageAction ?? '/age_check'}';
      log('\n--- Step 3: POST to age check: $ageUrl ---');

      final request = http.MultipartRequest('POST', Uri.parse(ageUrl))
        ..fields['authenticity_token'] = csrfToken;

      request.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';
      request.headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
      request.headers['Accept-Language'] = 'en-US,en;q=0.9';
      request.headers['Referer'] = baseUrl;
      request.headers['Cookie'] = cookieStr;

      final streamed = await request.send();
      final resp3 = await http.Response.fromStream(streamed);
      log('Age check status: ${resp3.statusCode}');

      final setCookie3 = resp3.headers['set-cookie'];
      log('Age check Set-Cookie: ${setCookie3?.substring(0, setCookie3.length.clamp(0, 300))}');

      // Update jar
      if (setCookie3 != null) {
        for (final part in setCookie3.split(',')) {
          final c = part.split(';').first.trim();
          final i = c.indexOf('=');
          if (i != -1) jar[c.substring(0, i)] = c.substring(i + 1);
        }
      }
    }

    // Step 5: Retry home with cookies
    final finalCookieStr = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
    log('\n--- Step 4: Retry /?tab=trending with cookies ---');
    log('Cookies: ${jar.keys.toList()}');

    final uri4 = Uri.parse('$baseUrl/?tab=trending');
    final resp4 = await http.get(uri4, headers: {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,application/json,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'X-Inertia': 'true',
      'X-Inertia-Version': '1',
      'Referer': baseUrl,
      'Cookie': finalCookieStr,
    });
    log('Retry status: ${resp4.statusCode}');

    final body4 = utf8.decode(resp4.bodyBytes);
    log('Retry body starts: ${body4.substring(0, body4.length.clamp(0, 200))}');

    if (body4.startsWith('{')) {
      log('\nSUCCESS: Got JSON response!');
      try {
        final json = jsonDecode(body4);
        log('Component: ${json['component']}');
        final props = json['props'] as Map<String, dynamic>;
        log('Props keys: ${props.keys.toList()}');
        final media = props['media'] as List<dynamic>?;
        log('Media count: ${media?.length}');
      } catch (e) {
        log('JSON parse error: $e');
      }
    } else {
      log('\nFAILED: Still getting HTML after all steps.');
      log('Full retry body (first 1000 chars):');
      log(body4.substring(0, body4.length.clamp(0, 1000)));
    }
  } else if (body1.startsWith('{')) {
    log('\nSUCCESS: First request returned JSON!');
    try {
      final json = jsonDecode(body1);
      log('Component: ${json['component']}');
      final props = json['props'] as Map<String, dynamic>;
      log('Props keys: ${props.keys.toList()}');
      final media = props['media'] as List<dynamic>?;
      log('Media count: ${media?.length}');
    } catch (e) {
      log('JSON parse error: $e');
    }
  }

  log('\n=== Test Complete ===');
  exit(0);
}
