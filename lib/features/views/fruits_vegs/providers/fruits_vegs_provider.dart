import 'package:flutter/material.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_category_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_score.dart';
import 'package:packer/features/views/fruits_vegs/repos/fruits_vegs_repo.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/utils/async_state.dart';
import 'package:packer/utils/paginated_response.dart';
import 'package:provider/provider.dart';

class FruitsVegsProvider with ChangeNotifier {
  AsyncState<PaginatedResponse<ProductModel>> fruitsVegsState =
      AsyncState.idle();

  //
  getFruitsVegsData(BuildContext context) async {
    try {
      fruitsVegsState = AsyncState.loading();
      notifyListeners();

      //
      final role = context.read<HomeProvider>().user.role;

      final response = await FruitsVegsRepo.getFruitsVegsData(role);
      fruitsVegsState = AsyncState.success(response);
    } catch (e) {
      fruitsVegsState = AsyncState.error(e.toString());
    } finally {
      notifyListeners();
    }
  }

  //

  assessFruitsVegsUnit({
    required BuildContext context,
    required String tagId,
    required RipenessCategoryEnum assessment,
    required RipenessScore score,
    required List<CanBeEatenEnum> canBeEaten,
  }) async {
    showLoading(context);
    try {
      await FruitsVegsRepo.assessFruitsVegsUnit(
        tagId: tagId,
        assessment: assessment,
        score: score,
        canBeEaten: canBeEaten,
        role: context.read<HomeProvider>().user.role,
      );
      removeLoading(context);

      Navigator.pop(context);
      showToast("Assessment submitted successfully");
    } catch (e) {
      removeLoading(context);
      showToast("Failed to submit assessment: ${e.toString()}");
    }
  }
}
