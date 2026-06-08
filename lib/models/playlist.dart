class Playlist {
  final String id;
  final String name;
  final String? description;
  final String visibility;
  final String slug;
  final int itemsCount;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.visibility,
    required this.slug,
    this.itemsCount = 0,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      slug: json['slug'] as String,
      itemsCount: json['items_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'visibility': visibility,
        'slug': slug,
        'items_count': itemsCount,
      };
}
