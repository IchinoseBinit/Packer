import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/services/api/enum/request_type.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/carton/model/carton_list_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/model/stock_item_model.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

class StockVerificationProvider extends ChangeNotifier {
  bool isLoading = false;

  List<StockItemModel> stockItems = [];
  List<String> rackList = [];
  Map<String, List<StockItemModel>> rackProductMap = {};

  StockItemModel? selectedStockItem;

  List<String> scannedUnits = [];
  Store? selectedStore;
  CartonListModel? selectedCarton;

  List<Store> storeList = [];
  // cartonList
  List<CartonListModel> cartonList = [];

  String scannedRackCode = "";
  String cartonId = "";
  int auditId = 0;

  void setSelectedStore(BuildContext context, Store store) async {
    selectedStore = store;
    auditId = 0;
    try {
      showLoading(context);
      final apiResponse = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.getAuditViewUrl,
        body: {
          "store_id": store.id,
        },
      );
      if (context.mounted) {
        removeLoading(context);
        if (apiResponse.statusCode == 200) {
          auditId = apiResponse.data['audit_id'].toString().toInt();
          navigate(context,
              route: NavigationConstants.stockRackScanScreenRoute,
              extra: {
                "changeRack": false,
              });
        } else {
          ErrorHandler.alertDialog(context, 'Failed to get audit view');
        }
      }
    } catch (e) {
      removeLoading(context);
      log("Error while getting audit view $e");
      ErrorHandler.alertDialog(context, e);
    }
  }

  void setSelectedCarton(CartonListModel carton) {
    scannedUnits.clear();
    selectedCarton = carton;
  }

  void arrangeStockItems() {
    rackList.clear();
    rackProductMap.clear();
    for (var element in stockItems) {
      if (!rackList.contains(element.rackName)) {
        rackList.add(element.rackName);
      }
      if (rackProductMap.containsKey(element.rackName)) {
        rackProductMap[element.rackName]!.add(element);
      } else {
        rackProductMap[element.rackName] = [element];
      }
    }

    // sort
    rackList.sort((a, b) => a.compareTo(b));
    notifyListeners();
  }

  Future<void> fetchCartonList(BuildContext context, int productId) async {
    try {
      final url = AppUrls.cartonListUrl
          .replaceFirst('product_id', productId.toString());

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );

      if (response.statusCode == 200) {
        cartonList = (response.data as List)
            .map((item) => CartonListModel.fromJson(item))
            .toList();
      } else {
        return;
      }
    } catch (e) {
      log('Error fetching carton list: $e');
      rethrow;
    }
  }

  Future<void> fetchStores() async {
    try {
      if (storeList.isNotEmpty) {
        return;
      }
      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getStoreUrl,
      );
      storeList =
          (response.data as List).map((e) => Store.fromJson(e)).toList();
      // if (storeList.isNotEmpty) {
      // } else {
      //   selectedStore = null;
      // }

      notifyListeners();
    } catch (e) {
      log("Error while getting value $e");
      notifyListeners();
    }
  }

  void getMessage(BuildContext context) {
    var message = "Scan Product Code";
    if (scannedUnits.isNotEmpty) {
      message += " Scanned ${scannedUnits.length} units";
    }
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  // fetch
  Future<void> fetchStockItems(BuildContext context, String storeId) async {
    try {
      rackList.clear();
      rackProductMap.clear();
      isLoading = true;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 0));

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: AppUrls.getStockItemsUrl.replaceAll("value", storeId),
      );
      stockItems = (response.data as List)
          .map((e) => StockItemModel.fromJson(e))
          .toList();
      isLoading = false;
      if (context.mounted) {
        navigate(context,
            route: NavigationConstants.stockRackScanScreenRoute,
            extra: {
              "changeRack": false,
            });
      }
    } catch (e) {
      log("Error while getting value $e");
      isLoading = false;
      notifyListeners();
    }
  }

  // onRackScan
  bool onRackScan(BuildContext context, String code) {
    try {
      scannedRackCode = code;
      scannedUnits.clear();

      if (selectedStore?.isMainStore ?? false) {
        navigateReplacement(context,
            route: NavigationConstants.cartonScanScreenRoute,
            extra: {
              'isMainStoreAudit': true,
            });
      } else {
        navigateReplacement(context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              'fromStockVerification': true,
            });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // onRackChangeScan
  bool onRackChangeScan(BuildContext context, String code) {
    try {
      scannedRackCode = code;
      if (selectedStore?.isMainStore ?? false) {
        navigate(context,
            route: NavigationConstants.stockRackScanScreenRoute,
            extra: {
              "changeRack": true,
            });
      } else {
        navigateReplacement(context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              'fromStockVerification': true,
            });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> getCartonIdentifier(BuildContext context, int id) async {
    try {
      final url = AppUrls.cartonDetailUrl.replaceFirst(':id', id.toString());

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );
      if (context.mounted) {
        if (response.statusCode == 200) {
          return response.data['unique_identifier']
              .toString()
              .toStringConversion();
        } else {
          if (context.mounted) {
            ErrorHandler.alertDialog(context, 'Failed to get carton info');
          }
          return "";
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.alertDialog(context, e);
      }
    }
    return "";
  }

  Future<int> getCartonId(BuildContext context, String identifier) async {
    try {
      final url = AppUrls.cartonByIdentifierUrl
          .replaceFirst(':identifier', identifier.toString());

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );
      if (context.mounted) {
        if (response.statusCode == 200) {
          return response.data['id'].toString().toInt();
        } else {
          if (context.mounted) {
            ErrorHandler.alertDialog(context, 'Failed to get carton info');
          }
          return 0;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.alertDialog(context, e.toString());
      }
    }
    return 0;
  }

  Future<void> getCartonInfo(BuildContext context, int id, String tag) async {
    try {
      final url = AppUrls.cartonDetailUrl.replaceFirst(':id', id.toString());

      final response = await DioClient().request(
        requestType: RequestType.getWithToken,
        url: url,
      );
      if (context.mounted) {
        if (response.statusCode == 200) {
          await navigateReplacement(context,
              route: NavigationConstants.cartonScanScreenRoute,
              extra: {
                'cartonId': id,
                'matchCode': true,
                'code': response.data['unique_identifier']
                    .toString()
                    .toStringConversion(),
                'tag': tag,
              });
        } else {
          if (context.mounted) {
            ErrorHandler.alertDialog(context, 'Failed to get carton info');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.alertDialog(context, e.toString());
      }
    }
  }

  // single verification
  Future<bool> singleVerification(
      BuildContext context, int id, String tag) async {
    final url = AppUrls.singleUnitVerificationUrl;
    if (checkCartonExist(id)) {
      getMessage(context);
      await navigateReplacement(context,
          route: NavigationConstants.productScanScreenRoute,
          extra: {
            "productId": selectedStockItem!.productId,
            "productUnits": selectedStockItem!.productUnits,
            "fromStockVerification": true,
          });
      return true;
    }

    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: url,
        body: {
          "carton_id": id,
          "product_unit": tag,
          "audit_id": auditId,
          "rack_id": scannedRackCode,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        showToast("Verification successful");
        getMessage(context);
        await navigateReplacement(context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              "fromStockVerification": true,
            });

        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> onItemTap(BuildContext context, StockItemModel item) async {
    selectedStockItem = item;
    selectedCarton = null;

    scannedUnits.clear();
    if (selectedStockItem != null) {
      if (selectedStockItem!.rackName.isNotEmpty) {
        final result = await navigate(context,
            route: NavigationConstants.scanRackRoute,
            extra: {
              "rack": selectedStockItem!.rackName,
              "productId": selectedStockItem!.productId
            });

        if (context.mounted && result) {
          if (selectedStore?.isMainStore ?? false) {
            final cartonListResults = await navigate(
              context,
              route: NavigationConstants.cartonListScreenRoute,
              extra: selectedStockItem!.productId,
            );
            // if (cartonListResults ?? false) {
            //   final productScanResults = await navigate(context,
            //       route: NavigationConstants.productScanScreenRoute,
            //       extra: {
            //         "productId": selectedStockItem!.productId,
            //         "productUnits": selectedStockItem!.productUnits,
            //         "fromStockVerification": true,
            //       });
            //   if (productScanResults ?? false) {
            //     // sacn product
            //   }
            // }
          } else if (result ?? false) {
            // sacn product
            final scanResults = await navigate(context,
                route: NavigationConstants.productScanScreenRoute,
                extra: {
                  "productId": selectedStockItem!.productId,
                  "productUnits": selectedStockItem!.productUnits,
                  "fromStockVerification": true,
                });
            if (scanResults ?? false) {
              // sacn product
            }
          }
        }
      } else {
        // scan product
        if (selectedStore?.isMainStore ?? false) {
          final cartonListResults = await navigate(
            context,
            route: NavigationConstants.cartonListScreenRoute,
            extra: selectedStockItem!.productId,
          );
        } else {
          final result = await navigate(context,
              route: NavigationConstants.productScanScreenRoute,
              extra: {
                "productId": selectedStockItem!.productId,
                "productUnits": selectedStockItem!.productUnits,
                "fromStockVerification": true,
              });
          if (result ?? false) {
            // navigate(context, route: NavigationConstants.cartonListScreenRoute, extra: {
            //   'product'
            // })
            // sacn product
          }
        }
      }
    }
  }

  // onScanCarton
  onScanCarton(BuildContext context, String code, {String? cartonCode}) async {
    cartonId = (await getCartonId(context, code)).toString();

    log("Carton ID Set $cartonId");

    // if (cartonCode == null) {
    //   // Find the carton by ID
    //   final carton = cartonList.firstWhereOrNull(
    //     (carton) => carton.uniqueIdentifier == code,
    //   );

    //   // Check if the carton exists and the code matches the unique identifier
    //   if (carton != null) {
    //     setSelectedCarton(carton);
    //     navigateReplacement(context,
    //         route: NavigationConstants.productScanScreenRoute,
    //         extra: {
    //           "productId": selectedStockItem!.productId,
    //           "productUnits": selectedStockItem!.productUnits,
    //           "fromStockVerification": true,
    //           'cartonId': selectedCarton!.id,
    //         });
    //     return true;
    //   } else {
    //     return false;
    //   }
    // } else if (selectedCarton != null) {
    //   if (selectedCarton!.uniqueIdentifier
    //       .toLowerCase()
    //       .contains(code.toLowerCase())) {
    //     navigateReplacement(context,
    //         route: NavigationConstants.productScanScreenRoute,
    //         extra: {
    //           "productId": selectedStockItem!.productId,
    //           "productUnits": selectedStockItem!.productUnits,
    //           "fromStockVerification": true,
    //           'cartonId': selectedCarton!.id,
    //         });
    //     return true;
    //   }
    // }

    // return false;
  }

  // onScanProduct
  bool onScanProduct(BuildContext context, int productId, String code,
      {bool fromStockVerification = false}) {
    // If carton scan is needed
    // if (selectedStore?.isMainStore ?? false) {
    //   final productCartonId = code.split("-")[2];
    //   if (productCartonId != cartonId) {
    //     return false;
    //   }
    // }
    if (scannedUnits.isEmpty) {
      scannedUnits.add(code);
    } else if (scannedUnits.contains(code)) {
      return false;
    } else {
      // check if scanned unit first tag split .first is same as code split .first
      final scannedUnitFirstTag = scannedUnits.first.split('-').first;
      final codeFirstTag = code.split('-').first;
      if (scannedUnitFirstTag != codeFirstTag) {
        return false;
      }

      scannedUnits.add(code);
    }

    if (fromStockVerification) {
      final quantity = scannedUnits.length;

      var message = "Scan Product Code";
      if (quantity > 0) {
        message += " Scanned $quantity units";
      }
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, message);
    } else {
      // check for the remaining or not
      var scanMessage = "";
      if (scannedUnits.length >= selectedStockItem!.productUnits.length) {
        scanMessage = "Scanned ${scannedUnits.length} units";
      } else {
        scanMessage =
            "Scan ${selectedStockItem!.productUnits.length - scannedUnits.length} more units";
      }
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, scanMessage);
    }

    notifyListeners();

    return true;
  }

  // This should only be called when the button on the ui is clicked.
  // The button would only be visible when the scanned units are equal to the product units.
  // The person can scan other units as well but the button would not be visible.
  Future<Map<String, dynamic>> onVerify() async {
    try {
      final response = await DioClient().request(
        requestType: RequestType.postWithToken,
        url: AppUrls.stockVerificationUrl,
        body: {
          "product": scannedUnits.first.split('-').first,
          "product_units": scannedUnits,
          "audit_id": auditId,
          "rack_id": scannedRackCode,
          if (selectedStore?.isMainStore ?? false) "carton_id": cartonId,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        scannedUnits.clear();
        cartonId = "";
        showToast("Verification successful");
        notifyListeners();
        return {
          'success': true,
          'message': 'Verification successful',
        };
      }
      return {
        'success': false,
        'message': 'Verification failed',
      };
    } catch (e) {
      scannedUnits.clear();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  completeCarton() {
    if (selectedCarton != null) removeStockItem(selectedStockItem!);
    selectedCarton = null;
    notifyListeners();
  }

  bool checkCartonExist(int cartonId) {
    return cartonList.any((carton) => carton.id == cartonId);
  }

  void removeStockItem(StockItemModel item) {
    final rackName = item.rackName;

    if (rackProductMap.containsKey(rackName)) {
      rackProductMap[rackName]!.remove(item);

      // If no more items in this rack, remove rack from list and map
      if (rackProductMap[rackName]!.isEmpty) {
        rackProductMap.remove(rackName);
        rackList.remove(rackName);
      }

      notifyListeners();
    }
  }
}
