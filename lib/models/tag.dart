class Tag {
  final String name;
  final String category;
  final int count;

  Tag({
    required this.name,
    required this.category,
    required this.count,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String,
      category: json['category'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'count': count,
      };
}
