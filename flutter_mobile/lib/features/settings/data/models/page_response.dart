/// Generic paginated-list envelope returned by Spring `PageResponse<T>`.
///
/// The actual backend record signature is:
///   `PageResponse.from(users.list(new PageQuery(...)), UserDto::from)`
/// which produces a JSON object shaped roughly like:
/// ```json
/// {
///   "items":    [ ... ],
///   "page":     1,
///   "pageSize": 20,
///   "total":    137
/// }
/// ```
///
/// Tolerant of alternate field names that often show up in Spring
/// Page-style DTOs (`content`, `totalElements`) — if the backend uses
/// those, the parser still picks the right values. If the real shape is
/// different again (e.g. cursor pagination), only this file needs to
/// change.
///
/// `T` is parsed by the [itemFromJson] callback provided at parse time
/// so the same envelope handles users, audit logs, sessions, etc.
class PageResponse<T> {
  const PageResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  /// `true` when more rows exist beyond the current page — used by lists
  /// to decide whether to render a "Load more" sentinel at the bottom.
  bool get hasMore => page * pageSize < total;

  static PageResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final rawItems =
        json['items'] ?? json['content'] ?? const <dynamic>[];
    final list = (rawItems as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(itemFromJson)
        .toList(growable: false);

    return PageResponse<T>(
      items: list,
      page: (json['page'] ?? json['number'] ?? 1) as int,
      pageSize: (json['pageSize'] ?? json['size'] ?? list.length) as int,
      total: (json['total'] ?? json['totalElements'] ?? list.length) as int,
    );
  }
}
