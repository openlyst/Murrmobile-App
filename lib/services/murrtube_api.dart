import 'dart:convert';
import 'dart:io';
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

  static Map<String, String> get _headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'X-Inertia': 'true',
        'X-Inertia-Version': '1',
        'Accept': 'application/json',
        if (_cookieString != null) 'Cookie': _cookieString!,
      };

  static Future<InertiaPage> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode} for $path');
    }
    final body = utf8.decode(response.bodyBytes);
    if (!body.startsWith('{')) {
      throw FormatException('Expected JSON for $path, got HTML');
    }
    return InertiaPage.fromJson(jsonDecode(body));
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
