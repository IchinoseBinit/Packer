import 'package:packer/features/views/low_stock/model/product_model.dart';

/// Page wrapper for `GET /staff/packer/stock-audit/`.
///
/// {
///   "next": null, "previous": null, "has_next_page": false, "page": 1,
///   "audit_id": 1,
///   "products": [ AuditProductModel... ]
/// }
class StockAuditPage {
  final List<AuditProductModel> products;
  final int page;
  final bool hasNextPage;
  final String? next;
  final String? previous;
  final int? auditId;
  final int? completedProducts;
  final int? expectedProducts;

  StockAuditPage({
    required this.products,
    required this.page,
    required this.hasNextPage,
    this.next,
    this.previous,
    this.auditId,
    this.completedProducts,
    this.expectedProducts,
  });

  factory StockAuditPage.fromJson(Map<String, dynamic> json) {
    final raw = json['products'] as List<dynamic>? ?? const [];
    return StockAuditPage(
      products: raw
          .whereType<Map<String, dynamic>>()
          .map(AuditProductModel.fromJson)
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      hasNextPage: (json['has_next_page'] as bool?) ?? (json['next'] != null),
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      auditId: (json['audit_id'] as num?)?.toInt(),
      completedProducts: (json['completed_products'] as num?)?.toInt(),
      expectedProducts: (json['expected_products'] as num?)?.toInt(),
    );
  }
}

/// Audit product = the shared [ProductModel] plus audit-only fields.
/// Backend will add `product_image`, `audit_type`, `is_completed`,
/// `expected_quantity` to each entry.
class AuditProductModel extends ProductModel {
  final String auditType;
  final bool isCompleted;
  final int expectedQuantity;

  AuditProductModel.fromJson(Map<String, dynamic> json)
      : auditType = json['audit_type']?.toString() ?? '',
        isCompleted = json['is_completed'] as bool? ?? false,
        expectedQuantity = (json['expected_quantity'] as num?)?.toInt() ?? 0,
        super.fromJson(json);
}
