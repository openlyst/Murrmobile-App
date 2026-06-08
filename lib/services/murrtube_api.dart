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
import '../models/playlist.dart';
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
  static String? currentUserSlug;

  static void setCookies(String cookies) {
    _cookieString = cookies;
  }

  static void clearCookies() {
    _cookieString = null;
    _inertiaVersion = null;
    currentUserSlug = null;
  }

  static String? _inertiaVersion;

  static void _updateCookiesFromResponse(http.Response response) {
    final setCookies = response.headers['set-cookie'];
    if (setCookies == null || _cookieString == null) return;

    final jar = <String, String>{};
    for (final part in _cookieString!.split('; ')) {
      final i = part.indexOf('=');
      if (i != -1) jar[part.substring(0, i)] = part.substring(i + 1);
    }
    for (final raw in setCookies.split(',')) {
      final c = raw.split(';').first.trim();
      final i = c.indexOf('=');
      if (i != -1) jar[c.substring(0, i)] = c.substring(i + 1);
    }
    _cookieString = jar.entries.map((e) => '${e.key}=${e.value}').join('; ');
    debugPrint('Updated cookies from response');
  }

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
    _updateCookiesFromResponse(response);
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
        _updateCookiesFromResponse(rootResp);
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
        _updateCookiesFromResponse(response);
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
    // 1. Plain JSON in script tags
    final versionRegex = RegExp(r'"version":"([^"]+)"');
    final match = versionRegex.firstMatch(html);
    if (match != null) {
      final v = match.group(1);
      debugPrint('Found version via regex: $v');
      return v;
    }
    // 2. data-page attribute with HTML-escaped JSON
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
    // 3. HTML-escaped &quot;version&quot; in raw HTML
    final quotRegex = RegExp(r'&quot;version&quot;:&quot;([^&]+)&quot;');
    final quotMatch = quotRegex.firstMatch(html);
    if (quotMatch != null) {
      final v = quotMatch.group(1);
      debugPrint('Found version via &quot; regex: $v');
      return v;
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
    if (currentUser != null) {
      currentUserSlug = currentUser.slug;
    }
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

  // User Profile
  static Future<({
    User user,
    List<Media> media,
    Pagination pagination,
    List<Playlist> playlists,
    bool isSubscribed,
    bool isSelf,
    User? currentUser,
    int? subscribersCount,
    int? subscriptionsCount,
    String? bio,
    String? telegramUrl,
    Map<String, int> tabCounts,
    String? gitlabUrl,
    String? twitterUrl,
    String? furaffinityUrl,
    String? patreonUrl,
    String? kofiUrl,
  })> getUserProfile(String slug, {int page = 1, String tab = 'videos'}) async {
    var path = '/$slug';
    if (tab != 'videos') path += '?tab=$tab';
    if (page != 1) path += path.contains('?') ? '&page=$page' : '?page=$page';
    final inertia = await _get(path);
    final props = inertia.props;

    final profileRaw = props['profile'];
    if (profileRaw == null || profileRaw is! Map<String, dynamic>) {
      debugPrint('ProfilePage missing profile. Available props keys: ${props.keys.toList()}');
      throw Exception('User not found for slug: $slug');
    }
    final user = User.fromJson(profileRaw);

    final mediaList = (props['media'] as List<dynamic>? ?? [])
        .map((m) => Media.fromJson(m as Map<String, dynamic>))
        .toList();
    final pagination = Pagination.fromJson(
      props['pagination'] as Map<String, dynamic>? ??
          {'page': 1, 'pages': 1, 'count': mediaList.length, 'next': null, 'prev': null},
    );
    final playlists = (props['playlists'] as List<dynamic>? ?? [])
        .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
        .toList();
    final currentUser = props['current_user'] != null
        ? User.fromJson(props['current_user'] as Map<String, dynamic>)
        : null;
    if (currentUser != null) {
      currentUserSlug = currentUser.slug;
    }
    final isSelf = props['viewing_self'] as bool? ?? false;
    if (isSelf) {
      currentUserSlug = user.slug;
    }
    final rawTabCounts = props['tab_counts'] as Map<String, dynamic>?;
    final tabCounts = <String, int>{};
    if (rawTabCounts != null) {
      for (final e in rawTabCounts.entries) {
        tabCounts[e.key] = e.value as int? ?? 0;
      }
    }
    return (
      user: user,
      media: mediaList,
      pagination: pagination,
      playlists: playlists,
      isSubscribed: props['is_subscribed'] as bool? ?? false,
      isSelf: isSelf,
      currentUser: currentUser,
      subscribersCount: tabCounts['subscribers'] ?? profileRaw['subscribers_count'] as int?,
      subscriptionsCount: tabCounts['subscriptions'] ?? profileRaw['subscriptions_count'] as int?,
      bio: profileRaw['bio'] as String? ?? profileRaw['description'] as String?,
      telegramUrl: profileRaw['telegram_url'] as String?,
      tabCounts: tabCounts,
      gitlabUrl: profileRaw['gitlab'] as String?,
      twitterUrl: profileRaw['twitter'] as String?,
      furaffinityUrl: profileRaw['furaffinity'] as String?,
      patreonUrl: profileRaw['patreon'] as String?,
      kofiUrl: profileRaw['kofi'] as String?,
    );
  }

  static Future<void> subscribeToUser(String userId) async {
    final token = await _fetchCsrfToken();
    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Referer': baseUrl,
        'Origin': baseUrl,
        'X-Requested-With': 'XMLHttpRequest',
        'x-csrf-token': token,
        if (_cookieString != null) 'Cookie': _cookieString!,
      },
      body: {'subscription[subscribed_to_id]': userId},
    );
    _updateCookiesFromResponse(response);
    debugPrint('subscribeToUser status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
  }

  static Future<void> unsubscribeFromUser(String userId) async {
    final token = await _fetchCsrfToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/subscriptions/$userId'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Referer': baseUrl,
        'Origin': baseUrl,
        'X-Requested-With': 'XMLHttpRequest',
        'x-csrf-token': token,
        if (_cookieString != null) 'Cookie': _cookieString!,
      },
    );
    _updateCookiesFromResponse(response);
    debugPrint('unsubscribeFromUser status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
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

  // Like / Unlike
  static Future<String> _fetchCsrfToken() async {
    // The XSRF-TOKEN cookie may be stale. Fetch a fresh token from HTML.
    final response = await http.get(
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
    _updateCookiesFromResponse(response);
    final html = utf8.decode(response.bodyBytes);
    final match = RegExp(r'<meta name="csrf-token" content="([^"]+)"').firstMatch(html);
    final token = match?.group(1);
    debugPrint('Fetched CSRF token: ${token != null ? "${token.substring(0, token.length.clamp(0, 30))}..." : "NOT FOUND"}');
    if (token == null || token.isEmpty) {
      throw Exception('CSRF token not found in HTML');
    }
    return token;
  }

  static Future<void> likeVideo(String mediumId) async {
    final token = await _fetchCsrfToken();
    final response = await http.post(
      Uri.parse('$baseUrl/likes'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Referer': baseUrl,
        'Origin': baseUrl,
        'X-Requested-With': 'XMLHttpRequest',
        'x-csrf-token': token,
        if (_cookieString != null) 'Cookie': _cookieString!,
      },
      body: {'like[medium_id]': mediumId},
    );
    _updateCookiesFromResponse(response);
    debugPrint('likeVideo status: ${response.statusCode}');
    debugPrint('likeVideo response body: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
  }

  static Future<void> unlikeVideo(String mediumId) async {
    final token = await _fetchCsrfToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/likes/$mediumId'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Referer': baseUrl,
        'Origin': baseUrl,
        'X-Requested-With': 'XMLHttpRequest',
        'x-csrf-token': token,
        if (_cookieString != null) 'Cookie': _cookieString!,
      },
    );
    _updateCookiesFromResponse(response);
    debugPrint('unlikeVideo status: ${response.statusCode}');
    debugPrint('unlikeVideo response body: ${utf8.decode(response.bodyBytes)}');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
  }

  // Playlists
  static Future<List<Playlist>> getMyPlaylists() async {
    final token = await _fetchCsrfToken();
    final response = await http.get(
      Uri.parse('$baseUrl/playlists/mine'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Referer': baseUrl,
        'x-csrf-token': token,
        'Cookie': _cookieString!,
      },
    );
    _updateCookiesFromResponse(response);
    final body = utf8.decode(response.bodyBytes);
    debugPrint('getMyPlaylists status: ${response.statusCode}');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    final playlists = (json['playlists'] as List<dynamic>? ?? [])
        .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
        .toList();
    return playlists;
  }

  static Future<Playlist> createPlaylist({
    required String name,
    String? description,
    required String visibility,
  }) async {
    final token = await _fetchCsrfToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/playlists'))
      ..fields['playlist[name]'] = name
      ..fields['playlist[visibility]'] = visibility;
    if (description != null && description.isNotEmpty) {
      request.fields['playlist[description]'] = description;
    }
    request.headers.addAll({
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'application/json',
      'Referer': baseUrl,
      'Origin': baseUrl,
      'X-Requested-With': 'XMLHttpRequest',
      'x-csrf-token': token,
      'Cookie': _cookieString!,
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _updateCookiesFromResponse(response);
    final body = utf8.decode(response.bodyBytes);
    debugPrint('createPlaylist status: ${response.statusCode}');
    debugPrint('createPlaylist body: $body');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    final json = jsonDecode(body) as Map<String, dynamic>;
    return Playlist(
      id: '',
      name: name,
      description: description,
      visibility: visibility,
      slug: json['slug'] as String,
    );
  }

  static Future<({
    Playlist playlist,
    List<Media> media,
    Pagination pagination,
    User? user,
    bool isOwner,
  })> getPlaylist(String slug, {int page = 1}) async {
    final path = page == 1 ? '/playlists/$slug' : '/playlists/$slug?page=$page';
    final inertia = await _get(path);
    final props = inertia.props;
    final playlist = Playlist.fromJson(props['playlist'] as Map<String, dynamic>);
    final mediaList = (props['media'] as List<dynamic>? ?? [])
        .map((m) => Media.fromJson(m as Map<String, dynamic>))
        .toList();
    final pagination = Pagination.fromJson(
      props['pagination'] as Map<String, dynamic>? ??
          {'page': 1, 'pages': 1, 'count': mediaList.length, 'next': null, 'prev': null},
    );
    final user = props['user'] != null
        ? User.fromJson(props['user'] as Map<String, dynamic>)
        : null;
    return (
      playlist: playlist,
      media: mediaList,
      pagination: pagination,
      user: user,
      isOwner: props['is_owner'] as bool? ?? false,
    );
  }

  static Future<void> addToPlaylist({
    required String playlistId,
    required String shortCode,
    required String mediumId,
  }) async {
    final token = await _fetchCsrfToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/playlists/$playlistId/items'),
    )
      ..fields['short_code'] = shortCode
      ..fields['medium_id'] = mediumId;
    request.headers.addAll({
      'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
      'Accept': 'application/json',
      'Referer': baseUrl,
      'Origin': baseUrl,
      'X-Requested-With': 'XMLHttpRequest',
      'x-csrf-token': token,
      'Cookie': _cookieString!,
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _updateCookiesFromResponse(response);
    final body = utf8.decode(response.bodyBytes);
    debugPrint('addToPlaylist status: ${response.statusCode}');
    debugPrint('addToPlaylist body: $body');
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
  }
}
