import 'package:flutter/material.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/leave_request/models/leave_request_model.dart';
import 'package:packer/features/views/leave_request/repo/leave_request_repo.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/utils/async_state.dart';
import 'package:packer/utils/paginated_response.dart';

class LeaveRequestProvider with ChangeNotifier {
  AsyncState<PaginatedResponse<LeaveRequest>> leaveState = AsyncState.idle();

  requestLeave({
    required BuildContext context,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      showLoading(context);
      await LeaveRequestRepo.submitLeaveRequest(
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
    } catch (e) {
      showToast(e.toString());
    } finally {
      removeLoading(context);
    }
  }

  //  get leave request status
  getLeaveRequest() async {
    try {
      leaveState = AsyncState.loading();
      notifyListeners();

      // call api
      final response = await LeaveRequestRepo.getLeaveRequest();

      leaveState = AsyncState.success(response);
      notifyListeners();
    } catch (e) {
      leaveState = AsyncState.error(e.toString());
      notifyListeners();
    }
  }

  //
}
