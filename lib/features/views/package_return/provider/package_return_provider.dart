import 'package:flutter/material.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/package_return/api/package_return_api.dart';
import 'package:packer/features/views/package_return/models/package_return_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';

class PackageReturnProvider extends ChangeNotifier {
  /// Loading states
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ///  Data
  PackageReturnModel? _packageReturn;

  PackageReturnModel? get packageReturnList => _packageReturn;

  ///  Error
  String? _error;
  String? get error => _error;

  ///  Fetch list
  Future<void> fetchPackageReturns() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await PackageReturnApi.fetchPackageReturnData();
      _packageReturn = response;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  ///
  Future<void> returnPackage(
    BuildContext context,
    int orderId,
    String packageId,
  ) async {
    try {
      showLoading(context);
      await PackageReturnApi.postPackageReturn(orderId, [packageId]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to return package: ${e.toString()}")),
      );
    } finally {
      removeLoading(context);
    }
  }
}
