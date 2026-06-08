import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/media.dart';
import '../models/comment.dart';
import '../models/pagination.dart';
import '../models/announcement.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../models/tag.dart';

class InertiaPage {
  final String component;
  final Map<String, dynamic> props;
  final String? version;

  InertiaPage({
    required this.component,
    required this.props,
    this.version,
  });

  factory InertiaPage.fromJson(Map<String, dynamic> json) {
    return InertiaPage(
      component: json['component'] as String,
      props: json['props'] as Map<String, dynamic>,
      version: json['version'] as String?,
    );
  }
}

class MurrtubeApi {
  static const String baseUrl = 'https://murrtube.net';
  static String? _cookieString;

  static bool get hasCookies => _cookieString != null && _cookieString!.isNotEmpty;

  static void setCookies(String cookies) {
    _cookieString = cookies;
  }

  static void clearCookies() {
    _cookieString = null;
  }

  static String? _inertiaVersion;

  static Map<String, String> _headers({String? inertiaVersion}) {
    final h = {
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,application/json,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'X-Inertia': 'true',
      if (inertiaVersion != null) 'X-Inertia-Version': inertiaVersion,
      'Referer': baseUrl,
      if (_cookieString != null) 'Cookie': _cookieString!,
    };
    debugPrint('--- headers ---');
    h.forEach((k, v) {
      if (k == 'Cookie') {
        debugPrint('Cookie: ${_maskCookie(v)}');
      } else {
        debugPrint('$k: $v');
      }
    });
    return h;
  }

  static String _maskCookie(String cookie) {
    final parts = cookie.split('; ');
    return parts.map((p) {
      final i = p.indexOf('=');
      if (i == -1) return p;
      final name = p.substring(0, i);
      final val = p.substring(i + 1);
      final show = val.length.clamp(0, 12);
      return '$name=${val.substring(0, show)}...(${val.length} chars)';
    }).join('; ');
  }

  static Future<InertiaPage> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    debugPrint('');
    debugPrint('=== MurrtubeApi._get $path ===');
    debugPrint('cookies set? ${hasCookies}');

    // Try with cached version first
    var response = await http.get(
      uri,
      headers: _headers(inertiaVersion: _inertiaVersion),
    );

    var body = utf8.decode(response.bodyBytes);
    debugPrint('First response status: ${response.statusCode}');
    debugPrint('First response body starts with: ${body.isNotEmpty ? body.substring(0, body.length.clamp(0, 60)) : "(empty)"}');

    // 409 = Inertia version mismatch. Body may be empty, so fetch root page
    // without Inertia headers to get HTML and extract the version.
    if (response.statusCode == 409 || !body.startsWith('{')) {
      debugPrint('Need to extract Inertia version and retry...');

      // If body is empty (common for 409), fetch root page normally
      if (body.isEmpty) {
        debugPrint('Body empty, fetching root page without Inertia headers...');
        final rootResp = await http.get(
          Uri.parse(baseUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': baseUrl,
            if (_cookieString != null) 'Cookie': _cookieString!,
          },
        );
        final rootBody = utf8.decode(rootResp.bodyBytes);
        debugPrint('Root page status: ${rootResp.statusCode}');
        debugPrint('Root page body starts with: ${rootBody.isNotEmpty ? rootBody.substring(0, rootBody.length.clamp(0, 60)) : "(empty)"}');
        _inertiaVersion = _extractInertiaVersion(rootBody);
      } else {
        _inertiaVersion = _extractInertiaVersion(body);
      }

      debugPrint('Extracted version: $_inertiaVersion');
      if (_inertiaVersion != null) {
        response = await http.get(
          uri,
          headers: _headers(inertiaVersion: _inertiaVersion),
        );
        body = utf8.decode(response.bodyBytes);
        debugPrint('Retry response status: ${response.statusCode}');
        debugPrint('Retry response body starts with: ${body.isNotEmpty ? body.substring(0, body.length.clamp(0, 60)) : "(empty)"}');
      }
    }

    if (response.statusCode != 200) {
      debugPrint('Final status code not 200, throwing.');
      throw HttpException('HTTP ${response.statusCode} for $path');
    }

    if (!body.startsWith('{')) {
      debugPrint('Body is not JSON after retries, throwing.');
      throw FormatException('Expected JSON for $path, got HTML');
    }

    debugPrint('Parsing JSON response...');
    return InertiaPage.fromJson(jsonDecode(body));
  }

  static String? _extractInertiaVersion(String html) {
    debugPrint('Extracting Inertia version from HTML (${html.length} chars)');
    // Look for Inertia version in script tags
    final versionRegex = RegExp(r'"version":"([^"]+)"');
    final match = versionRegex.firstMatch(html);
    if (match != null) {
      final v = match.group(1);
      debugPrint('Found version via regex: $v');
      return v;
    }
    // Alternative: look for data-page attribute (HTML-escaped JSON)
    final dataPageRegex = RegExp(r'data-page="([^"]+)"');
    final dataMatch = dataPageRegex.firstMatch(html);
    if (dataMatch != null) {
      try {
        final raw = dataMatch.group(1)!;
        final cleaned = raw
            .replaceAll('&quot;', '"')
            .replaceAll('\\"', '"')
            .replaceAll('\\n', '\n');
        final decoded = jsonDecode(cleaned);
        if (decoded is Map<String, dynamic>) {
          final v = decoded['version'] as String?;
          debugPrint('Found version via data-page: $v');
          return v;
        }
      } catch (e) {
        debugPrint('data-page parse failed: $e');
      }
    }
    debugPrint('No version found in HTML');
    return null;
  }

  // Home (trending / subscriptions)
  static Future<({
    List<Media> media,
    Pagination pagination,
    List<Announcement> announcements,
    String tab,
    User? currentUser,
  })> getHome({String tab = 'trending', int page = 1}) async {
    final path = page == 1 ? '/?tab=$tab' : '/?tab=$tab&page=$page';
    final inertia = await _get(path);
    final props = inertia.props;
    final mediaList = (props['media'] as List<dynamic>)
        .map((m) => Media.fromJson(m as Map<String, dynamic>))
        .toList();
    final pagination = Pagination.fromJson(props['pagination'] as Map<String, dynamic>);
    final announcements = (props['announcements'] as List<dynamic>)
        .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
        .toList();
    final currentUser = props['current_user'] != null
        ? User.fromJson(props['current_user'] as Map<String, dynamic>)
        : null;
    return (
      media: mediaList,
      pagination: pagination,
      announcements: announcements,
      tab: props['tab'] as String? ?? tab,
      currentUser: currentUser,
    );
  }

  // Video detail
  static Future<({
    Media medium,
    List<Comment> comments,
    Pagination commentsPagination,
    List<Media> watchMore,
    bool viewerCanComment,
    bool viewerCanLike,
  })> getVideo(String shortCode) async {
    final inertia = await _get('/v/$shortCode');
    final props = inertia.props;
    final medium = Media.fromJson(props['medium'] as Map<String, dynamic>);
    final comments = (props['comments'] as List<dynamic>)
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
    final commentsPagination =
        Pagination.fromJson(props['comments_pagination'] as Map<String, dynamic>);
    final watchMore = (props['watch_more'] as List<dynamic>? ?? [])
        .map((m) => Media.fromJson(m as Map<String, dynamic>))
        .toList();
    return (
      medium: medium,
      comments: comments,
      commentsPagination: commentsPagination,
      watchMore: watchMore,
      viewerCanComment: props['viewer_can_comment'] as bool? ?? false,
      viewerCanLike: props['viewer_can_like'] as bool? ?? false,
    );
  }

  // Search
  static Future<({
    String? query,
    List<Media> media,
    List<User> users,
    List<Tag> tagMatches,
    Pagination pagination,
  })> search({String? query, int page = 1}) async {
    final q = query != null && query.isNotEmpty ? Uri.encodeComponent(query) : '';
    final path = '/search?q=$q&page=$page';
    final inertia = await _get(path);
    final props = inertia.props;
    final mediaList = (props['media'] as List<dynamic>)
        .map((m) => Media.fromJson(m as Map<String, dynamic>))
        .toList();
    final users = (props['users'] as List<dynamic>? ?? [])
        .map((u) => User.fromJson(u as Map<String, dynamic>))
        .toList();
    final tagMatches = (props['tag_matches'] as List<dynamic>? ?? [])
        .map((t) => Tag.fromJson(t as Map<String, dynamic>))
        .toList();
    final pagination =
        Pagination.fromJson(props['pagination'] as Map<String, dynamic>);
    return (
      query: props['query'] as String?,
      media: mediaList,
      users: users,
      tagMatches: tagMatches,
      pagination: pagination,
    );
  }

  // Notifications
  static Future<({
    List<NotificationItem> items,
    int displayCap,
  })> getNotifications() async {
    final inertia = await _get('/notifications');
    final props = inertia.props;
    final items = (props['items'] as List<dynamic>)
        .map((i) => NotificationItem.fromJson(i as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      displayCap: props['display_cap'] as int? ?? 0,
    );
  }

  // Settings
  static Future<Map<String, dynamic>> getSettings() async {
    final inertia = await _get('/settings');
    return inertia.props;
  }

  // Upload
  static Future<Map<String, dynamic>> getUpload() async {
    final inertia = await _get('/upload');
    return inertia.props;
  }

  // About pages
  static Future<Map<String, dynamic>> getTerms() async {
    final inertia = await _get('/about/terms');
    return inertia.props;
  }

  static Future<Map<String, dynamic>> getPrivacy() async {
    final inertia = await _get('/about/privacy');
    return inertia.props;
  }

  static Future<Map<String, dynamic>> getCookies() async {
    final inertia = await _get('/about/cookies');
    return inertia.props;
  }

  static Future<Map<String, dynamic>> getWhatsNew() async {
    final inertia = await _get('/about/whats-new');
    return inertia.props;
  }
}
