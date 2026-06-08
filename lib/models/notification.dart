class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? url;
  final DateTime createdAt;
  final bool read;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.url,
    required this.createdAt,
    required this.read,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      url: json['url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      read: json['read'] as bool? ?? false,
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
