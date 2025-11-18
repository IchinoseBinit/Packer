// providers/vendor_provider.dart
import 'package:flutter/material.dart';
import 'package:packer/features/views/vendor/repo/vendor_repo.dart';
import '../models/vendor_model.dart';

enum VendorState { initial, loading, loaded, error }

class VendorProvider extends ChangeNotifier {
  final VendorRepo _vendorService = VendorRepo();

  VendorState _state = VendorState.initial;
  VendorState get state => _state;

  VendorModel? _vendorData;
  VendorModel? get vendorData => _vendorData;

  List<Vendors> _filteredVendors = [];
  List<Vendors> get filteredVendors => _filteredVendors;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVendors() async {
    _state = VendorState.loading;
    notifyListeners();

    try {
      _vendorData = await _vendorService.fetchVendors();
      _filteredVendors = _vendorData?.vendors ?? [];
      _state = VendorState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = VendorState.error;
    }

    notifyListeners();
  }

  void searchVendors(String query) {
    if (query.isEmpty) {
      _filteredVendors = _vendorData?.vendors ?? [];
    } else {
      _filteredVendors = _vendorData?.vendors
              .where((v) =>
                  v.name.toLowerCase().contains(query.toLowerCase()) ||
                  v.company.toLowerCase().contains(query.toLowerCase()))
              .toList() ??
          [];
    }
    notifyListeners();
  }
}
