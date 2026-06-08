import 'package:flutter_test/flutter_test.dart';
import 'package:murrmobile/models/user.dart';
import 'package:murrmobile/models/media.dart';
import 'package:murrmobile/models/comment.dart';
import 'package:murrmobile/models/tag.dart';
import 'package:murrmobile/models/pagination.dart';

void main() {
  group('Model parsing', () {
    test('User.fromJson parses correctly', () {
      final user = User.fromJson({
        'id': '42aa60df-319d-434a-a8d4-132faa3ffb5f',
        'slug': 'http-animations',
        'name': 'HttpAnimations',
        'avatar_url': 'https://example.com/avatar.jpg',
        'is_admin': false,
        'is_owner': true,
        'preferred_video_quality': 'auto',
      });
      expect(user.id, '42aa60df-319d-434a-a8d4-132faa3ffb5f');
      expect(user.name, 'HttpAnimations');
      expect(user.isOwner, true);
    });

    test('Tag.fromJson parses correctly', () {
      final tag = Tag.fromJson({
        'name': 'ass',
        'category': 'general',
        'count': 1427,
      });
      expect(tag.name, 'ass');
      expect(tag.count, 1427);
    });

    test('Media.fromJson parses correctly', () {
      final media = Media.fromJson({
        'id': '71facd87-c112-4f49-9b6f-bed21eb53d79',
        'short_code': 'A1JY',
        'title': 'Test Video',
        'url': '/v/A1JY',
        'duration': 352,
        'duration_label': '5:52',
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'preview_url': 'https://example.com/preview.gif',
        'status': 'published',
        'likes_count': 40,
        'views_count': 3943,
        'published_at': '2026-05-31T23:07:33Z',
        'created_at': '2026-05-31T21:04:45Z',
        'user': {
          'id': 'user-id',
          'slug': 'test-user',
          'name': 'Test User',
          'avatar_url': null,
          'is_admin': false,
          'is_owner': false,
          'preferred_video_quality': 'auto',
        },
        'description': 'A test video',
        'visibility': 'public',
        'comments_disabled': false,
        'comments_count': 13,
        'tags': [
          {'name': 'test', 'category': 'general', 'count': 10}
        ],
        'viewer_liked': false,
        'is_owner': false,
        'is_live': true,
        'hls_url': 'https://example.com/video.m3u8',
      });
      expect(media.shortCode, 'A1JY');
      expect(media.title, 'Test Video');
      expect(media.user.name, 'Test User');
      expect(media.tags.length, 1);
      expect(media.hlsUrl, 'https://example.com/video.m3u8');
    });

    test('Comment.fromJson parses correctly', () {
      final comment = Comment.fromJson({
        'id': 'comment-1',
        'body': 'Nice video!',
        'created_at': '2026-05-31T23:07:33Z',
        'replies_count': 2,
        'is_creator': false,
        'is_owner': false,
        'user': {
          'id': 'user-id',
          'slug': 'commenter',
          'name': 'Commenter',
          'avatar_url': null,
          'is_admin': false,
          'is_owner': false,
          'preferred_video_quality': 'auto',
        },
        'replies': [],
      });
      expect(comment.body, 'Nice video!');
      expect(comment.repliesCount, 2);
    });

    test('Pagination.fromJson parses correctly', () {
      final pagination = Pagination.fromJson({
        'page': 1,
        'pages': 5,
        'count': 120,
        'next': '/?page=2',
        'prev': null,
      });
      expect(pagination.page, 1);
      expect(pagination.next, '/?page=2');
      expect(pagination.prev, isNull);
    });
  });
}
