import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';

class ShiftClockRepo {
  // GET /attendance/session/
  static Future<ShiftSessionState> getSession() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.attendanceSessionUrl,
      );
      return _parse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // POST /attendance/request/ -> 201 with the session state
  static Future<ShiftSessionState> requestExtension({
    required double hours,
    required String payType,
    String reason = '',
  }) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.attendanceRequestUrl,
        body: {
          "hours": hours,
          "pay_type": payType,
          "reason": reason,
        },
      );
      return _parse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // POST /attendance/request/<id>/cancel/ -> 200 with the session state
  static Future<ShiftSessionState> cancelRequest(int id) async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.attendanceCancelRequestUrl(id),
        body: {},
      );
      return _parse(response.data);
    } catch (e) {
      rethrow;
    }
  }

  static ShiftSessionState _parse(dynamic data) {
    if (data is! Map) {
      throw const FormatException('Unexpected shift clock response');
    }
    return ShiftSessionState.fromJson(data);
  }
}
