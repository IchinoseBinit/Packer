class PaginatedResponse<T> {
  final List<T> results;
  final int page;
  final bool hasNextPage;

  PaginatedResponse({
    required this.results,
    required this.page,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawList = json['results'] as List<dynamic>? ?? [];

    return PaginatedResponse<T>(
      results:
          rawList.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      page: json['page'] ?? 1,
      hasNextPage: json['has_next_page'] ?? false,
    );
  }
}
