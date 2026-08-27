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
  AsyncState<PaginatedResponse<ProductModel>> allState = AsyncState.idle();
  AsyncState<PaginatedResponse<ProductModel>> checkedState = AsyncState.idle();

  final List<ProductModel> _allItems = [];
  final List<ProductModel> _checkedItems = [];
  bool _allHasNext = false;
  bool _checkedHasNext = false;
  int _allNextPage = 1;
  int _checkedNextPage = 1;
  bool _isLoadingMoreAll = false;
  bool _isLoadingMoreChecked = false;

  // last-used params so loadMore can reuse them
  int? _allStoreId;
  DateTime? _allDate;
  int? _checkedStoreId;
  DateTime? _checkedDate;

  AsyncState<PaginatedResponse<ProductModel>> stateFor(bool checkedProducts) =>
      checkedProducts ? checkedState : allState;

  List<ProductModel> itemsFor(bool checkedProducts) =>
      checkedProducts ? _checkedItems : _allItems;

  bool hasNextFor(bool checkedProducts) =>
      checkedProducts ? _checkedHasNext : _allHasNext;

  bool isLoadingMoreFor(bool checkedProducts) =>
      checkedProducts ? _isLoadingMoreChecked : _isLoadingMoreAll;

  getFruitsVegsData(
    BuildContext context, {
    bool checkedProducts = false,
    int? storeId,
    DateTime? date,
  }) async {
    try {
      if (checkedProducts) {
        _checkedItems.clear();
        _checkedNextPage = 1;
        _checkedHasNext = false;
        _checkedStoreId = storeId;
        _checkedDate = date;
        checkedState = AsyncState.loading();
      } else {
        _allItems.clear();
        _allNextPage = 1;
        _allHasNext = false;
        _allStoreId = storeId;
        _allDate = date;
        allState = AsyncState.loading();
      }
      notifyListeners();

      final role = context.read<HomeProvider>().user.role;

      final response = await FruitsVegsRepo.getFruitsVegsData(
        role,
        checkedProducts: checkedProducts,
        storeId: storeId,
        date: date,
        page: 1,
      );

      if (checkedProducts) {
        _checkedItems.addAll(response.results);
        _checkedHasNext = response.hasNextPage;
        _checkedNextPage = response.page + 1;
        checkedState = AsyncState.success(response);
      } else {
        _allItems.addAll(response.results);
        _allHasNext = response.hasNextPage;
        _allNextPage = response.page + 1;
        allState = AsyncState.success(response);
      }
    } catch (e) {
      if (checkedProducts) {
        checkedState = AsyncState.error(e.toString());
      } else {
        allState = AsyncState.error(e.toString());
      }
    } finally {
      notifyListeners();
    }
  }

  loadMoreFruitsVegsData(
    BuildContext context, {
    bool checkedProducts = false,
  }) async {
    if (checkedProducts) {
      if (_isLoadingMoreChecked || !_checkedHasNext) return;
      _isLoadingMoreChecked = true;
    } else {
      if (_isLoadingMoreAll || !_allHasNext) return;
      _isLoadingMoreAll = true;
    }
    notifyListeners();

    try {
      final role = context.read<HomeProvider>().user.role;
      final page = checkedProducts ? _checkedNextPage : _allNextPage;
      final storeId = checkedProducts ? _checkedStoreId : _allStoreId;
      final date = checkedProducts ? _checkedDate : _allDate;

      final response = await FruitsVegsRepo.getFruitsVegsData(
        role,
        checkedProducts: checkedProducts,
        storeId: storeId,
        date: date,
        page: page,
      );

      if (checkedProducts) {
        _checkedItems.addAll(response.results);
        _checkedHasNext = response.hasNextPage;
        _checkedNextPage = response.page + 1;
      } else {
        _allItems.addAll(response.results);
        _allHasNext = response.hasNextPage;
        _allNextPage = response.page + 1;
      }
    } catch (_) {
      // loadMore failures are silent — user can scroll again to retry
    } finally {
      if (checkedProducts) {
        _isLoadingMoreChecked = false;
      } else {
        _isLoadingMoreAll = false;
      }
      notifyListeners();
    }
  }

  assessFruitsVegsUnit({
    required BuildContext context,
    required String tagId,
    RipenessCategoryEnum? assessment,
    RipenessScore? score,
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
      //
      removeLoading(context);

      scannedTags.add(tagId);

      notifyListeners();

      Navigator.pop(context); // pop the RateRipenessWidget
      showToast("Assessment submitted successfully");
    } catch (e) {
      removeLoading(context);
      showToast("Failed to submit assessment: ${e.toString()}");
    }
  }

  clearScannedTags() {
    scannedTags.clear();
    notifyListeners();
  }

  //
  List<String> scannedTags = [];
}
