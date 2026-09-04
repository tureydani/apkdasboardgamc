/// Espeja la forma { items, total, page, pageSize } que devuelven todas las
/// rutas de listado de /api/dashboard/** (ver crud-factory del backend).
class PagedResult {
  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final int pageSize;

  PagedResult({required this.items, required this.total, required this.page, required this.pageSize});

  factory PagedResult.fromJson(Map<String, dynamic> json) {
    return PagedResult(
      items: (json['items'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}
