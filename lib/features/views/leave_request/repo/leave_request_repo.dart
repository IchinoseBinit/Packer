import 'package:intl/intl.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/leave_request/models/leave_request_model.dart';
import 'package:packer/utils/paginated_response.dart';

class LeaveRequestRepo {
  //
  static Future<LeaveRequest> submitLeaveRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final body = {
        "start_date": DateFormat('yyyy-MM-dd').format(startDate),
        "end_date": DateFormat('yyyy-MM-dd').format(endDate),
        "reason": reason
      };
      //
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.leaveRequestUrl,
        body: body,
      );

      return LeaveRequest.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  //  get leave request status
  static Future<PaginatedResponse<LeaveRequest>> getLeaveRequest() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.leaveRequestUrl,
      );

      return PaginatedResponse.fromJson(
        response.data,
        LeaveRequest.fromJson,
      );
    } catch (e) {
      rethrow;
    }
  }
}
