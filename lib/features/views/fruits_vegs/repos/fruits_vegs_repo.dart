import 'package:intl/intl.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_category_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_score.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/utils/paginated_response.dart';

class FruitsVegsRepo {
  /// Get fruits and vegetables data
  static Future<PaginatedResponse<ProductModel>> getFruitsVegsData(
    UserRole role, {
    bool checkedProducts = false,
    int? storeId,
    DateTime? date,
    int page = 1,
  }) async {
    try {
      final url = checkedProducts
          ? AppUrls.checkedProductsUrl
          : (role == UserRole.productChecker
              ? AppUrls.productCheckerUrl
              : AppUrls.fruitsVegsUrl);

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
        queryParameters: {
          if (storeId != null) "store_id": storeId,
          if (date != null) "date": DateFormat('yyyy-MM-dd').format(date),
          "page": page,
        },
      );
      return PaginatedResponse.fromJson(response.data, ProductModel.fromJson);
    } catch (e) {
      rethrow;
    }
  }

  //
  static Future<void> assessFruitsVegsUnit({
    required String tagId,
    RipenessCategoryEnum? assessment,
    RipenessScore? score,
    required List<CanBeEatenEnum>
        canBeEaten, // List of CanBeEatenEnum values for day 1 to day 5
    required UserRole role,
  }) async {
    try {
      await DioClient().request(
        requestType: RequestType.postWithToken,
        url: role == UserRole.productChecker
            ? AppUrls.productCheckerAssessUrl
            : AppUrls.fruitsVegsAssessUrl,
        body: {
          "tag": tagId,
          if (assessment != null) "ripeness_category": assessment.value,
          if (score != null) "ripeness_score": score.score,
          "can_be_eaten": canBeEaten.map((e) => e.value).toList(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
