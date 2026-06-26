import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/audit_product/models/stock_audit_model.dart';

class StockAuditRepo {
  /// Fetch one page of the stock audit list, with optional filters.
  static Future<StockAuditPage> getStockAudit({
    int? storeId,
    String? auditType,
    bool? isCompleted,
    int page = 1,
  }) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.stockAuditUrl,
        queryParameters: {
          if (storeId != null) "store_id": storeId,
          if (auditType != null && auditType.isNotEmpty)
            "audit_type": auditType,
          if (isCompleted != null) "is_completed": isCompleted,
          "page": page,
        },
      );
      return StockAuditPage.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Start a new stock audit session.
  static Future<void> startAudit() async {
    try {
      await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockAuditStartUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Submit the scanned tags for one audited product.
  static Future<void> submitAuditItem({
    required int auditId,
    required int productId,
    required String auditType,
    required List<String> scannedTags,
  }) async {
    try {
      await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockAuditItemUrl,
        body: {
          "audit_id": auditId,
          "product_id": productId,
          "audit_type": auditType,
          "scanned_tags": scannedTags,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Mark the whole audit session complete.
  static Future<void> completeAudit({required int auditId}) async {
    try {
      await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockAuditCompleteUrl,
        body: {"audit_id": auditId},
      );
    } catch (e) {
      rethrow;
    }
  }
}
