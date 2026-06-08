class User {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;
  final bool isAdmin;
  final bool isOwner;
  final String preferredVideoQuality;

  User({
    required this.id,
    required this.slug,
    required this.name,
    this.avatarUrl,
    required this.isAdmin,
    required this.isOwner,
    required this.preferredVideoQuality,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
      preferredVideoQuality: json['preferred_video_quality'] as String? ?? 'auto',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
        'avatar_url': avatarUrl,
        'is_admin': isAdmin,
        'is_owner': isOwner,
        'preferred_video_quality': preferredVideoQuality,
      };
}
