class NotificationActor {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;

  NotificationActor({
    required this.id,
    required this.slug,
    required this.name,
    this.avatarUrl,
  });

  factory NotificationActor.fromJson(Map<String, dynamic> json) {
    return NotificationActor(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? url;
  final DateTime createdAt;
  final bool read;
  final NotificationActor? actor;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.url,
    required this.createdAt,
    required this.read,
    this.actor,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // murrtube API returns int id, not string
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : rawId as String;

    // Build a sensible title from actor + verb
    final actor = json['actor'] != null
        ? NotificationActor.fromJson(json['actor'] as Map<String, dynamic>)
        : null;
    final verb = json['verb'] as String? ?? '';
    final title = actor != null ? '${actor.name} $verb' : verb;

    // Body can come from various fields depending on notification type
    var body = json['comment_body'] as String? ??
        json['body'] as String? ??
        json['video_title'] as String? ??
        '';
    // Strip carriage returns
    body = body.replaceAll('\r', '');

    return NotificationItem(
      id: id,
      type: json['key'] as String? ?? json['kind'] as String? ?? 'unknown',
      title: title,
      body: body,
      url: json['link'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      read: !(json['is_unread'] as bool? ?? false),
      actor: actor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'url': url,
        'created_at': createdAt.toIso8601String(),
        'read': read,
      };
}
