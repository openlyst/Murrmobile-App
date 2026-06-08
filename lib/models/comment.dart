import 'user.dart';

class Comment {
  final String id;
  final String body;
  final DateTime createdAt;
  final int repliesCount;
  final bool isCreator;
  final bool isOwner;
  final User user;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.repliesCount,
    required this.isCreator,
    required this.isOwner,
    required this.user,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      repliesCount: json['replies_count'] as int? ?? 0,
      isCreator: json['is_creator'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => Comment.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'replies_count': repliesCount,
        'is_creator': isCreator,
        'is_owner': isOwner,
        'user': user.toJson(),
        'replies': replies.map((r) => r.toJson()).toList(),
      };
}
