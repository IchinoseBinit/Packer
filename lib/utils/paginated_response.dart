class PaginatedResponse<T> {
  final List<T> results;
  final int page;
  final bool hasNextPage;
  final int? count;
  final int? totalPages;
  final String? next;

  PaginatedResponse({
    required this.results,
    required this.page,
    required this.hasNextPage,
    this.count,
    this.totalPages,
    this.next,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawList = json['results'] as List<dynamic>? ?? [];

    return PaginatedResponse<T>(
      results:
          rawList.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      page: json['page'] ?? json['current_page'] ?? 1,
      hasNextPage: (json['has_next_page'] ?? json['next']) != null,
      count: json['count'],
      totalPages: json['total_pages'],
      next: json['next'],
    );
  }
}
