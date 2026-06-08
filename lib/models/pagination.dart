class Pagination {
  final int page;
  final int pages;
  final int count;
  final dynamic next;
  final dynamic prev;

  Pagination({
    required this.page,
    required this.pages,
    required this.count,
    this.next,
    this.prev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      pages: json['pages'] as int,
      count: json['count'] as int,
      next: json['next'],
      prev: json['prev'],
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'pages': pages,
        'count': count,
        'next': next,
        'prev': prev,
      };
}
