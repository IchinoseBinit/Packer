import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'base_scan_screen.dart';

// ignore: must_be_immutable
class ProductScanScreen extends BaseScanScreen {
  final int productId;
  bool hasScanned = false;
  bool fromStockVerification = false;
  int? cartonId;
  bool fromTransfer = false;
  bool forCarton = false;
  bool forDamageTransfer;
  bool forDamageReceive = false;

  ProductScanScreen({
    super.key,
    required this.productId,
    this.fromStockVerification = false,
    this.cartonId,
    this.fromTransfer = false,
    this.forCarton = false,
    this.forDamageTransfer = false,
    this.forDamageReceive = false,
  }) : super(
          scanTitle: 'Product Scanner',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: fromTransfer || forCarton
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    if (forCarton) {
      Provider.of<StockProvider>(context, listen: false)
          .getMessageForCartonProduct(context);
    } else if (fromStockVerification) {
      Provider.of<StockVerificationProvider>(context, listen: false)
          .getMessage(context);
    } else if (!fromTransfer) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Product Code");
    }
    // else if (forDamageReceive) {
    //   Provider.of<ScanMessageProvider>(context, listen: false)
    //       .setMessage(context, "Scan Product Code Received");
    // }
  }

  bool isProcessing = false;
  List<String> scannedCodes = [];

  // list of scanned units

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (forCarton) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<StockProvider>(context, listen: false)
              .showCartonProductTags(context);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    if (forDamageTransfer) {
      return GeneralElevatedButton(
        onPressed: () async {
          orderProvider.damageProductTransfer(context);
        },
        title: "Confirm Transfer",
      );
    }
    // if (forDamageReceive) {
    //   return Padding(
    //     padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
    //     child: GeneralElevatedButton(
    //       onPressed: () async {
    //         final productId = Provider.of<OrderProvider>(context, listen: false)
    //             .damageProductId;
    //         controller.stop();
    //         final result = await navigateReplacement(
    //           context,
    //           route: NavigationConstants.scanRackRoute,
    //           extra: {
    //             'productId': productId.toInt(),
    //             'forDamage': true,
    //           },
    //         );

    //         if (result == true) {
    //           showToast("Damage product scanned & rack updated!");
    //         }
    //       },
    //       title: "Done",
    //     ),
    //   );
    // }
    if (fromTransfer) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<PackerTransferProvider>(context, listen: false)
              .showProductTags(context, productId);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    final provider = Provider.of<StockVerificationProvider>(context);

    if (provider.scannedUnits.isEmpty) {
      if (provider.selectedStore?.isMainStore ?? false) {
        return SizedBox.shrink();
      }
      return GeneralElevatedButton(
        marginH: 16,
        title: 'Change Rack',
        onPressed: () {
          navigateReplacement(context,
              route: NavigationConstants.stockRackScanScreenRoute,
              extra: {
                'changeRack': false,
              });
        },
      );
    } else {
      return GeneralElevatedButton(
        marginH: 16,
        onPressed: () async {
          controller.stop();
          final scanned = provider.scannedUnits.length;

          if (scanned == 0) {
            return;
          }

          // Show confirmation dialog
          final shouldContinue = await ShowAlertDialog(
            body: Text(
              "Are you sure you want to complete verification?\n"
              "Scanned Units: $scanned",
            ),
            needCancel: true,
            disableBackground: true,
            okFunc: () => Navigator.pop(context, true),
            cancelFunc: () {
              controller.start();
              Navigator.pop(context, false);
            },
          ).showAlertDialog(context);

          if (shouldContinue != true) return;
          if (!context.mounted) return;
          showLoading(context);
          final result = await provider.onVerify();

          if (!context.mounted) return;
          if (result['success'] == false) {
            if (!context.mounted) return;

            Provider.of<ScanMessageProvider>(context, listen: false)
                .setMessage(context, "Scan Product Code");

            removeLoading(context);
            ShowAlertDialog(
              disableBackground: true,
              body: Text(result['message']),
              okFunc: () {
                removeLoading(context);
                Navigator.pop(context);
                controller.start();
              },
            ).showAlertDialog(context);
          } else {
            Future.delayed(Duration(seconds: 1), () {
              if (!context.mounted) return;

              removeLoading(context);
              if (Provider.of<StockVerificationProvider>(context, listen: false)
                      .selectedStore
                      ?.isMainStore ??
                  false) {
                navigateReplacement(context,
                    route: NavigationConstants.cartonScanScreenRoute,
                    extra: {
                      'isMainStoreAudit': true,
                    });
              } else {
                controller.start();
                Provider.of<ScanMessageProvider>(context, listen: false)
                    .setMessage(context, "Scan Product Code");
              }
            });
          }
        },
        title: "Complete Verification",
      );
    }
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();
      HapticFeedback.heavyImpact();

      if (code.contains("carton") ||
          code.contains("rack") ||
          code.contains("basket")) {
        handleInvalidCode(
            context, controller, code, "Please scan a product code");
        return;
      }

      // split code to get product id
      if (productId > 0) {
        final list = code.split('-');
        final prodId = int.tryParse(list.first) ?? 0;
        if (prodId != productId) {
          handleInvalidCode(context, controller, code);
          return;
        }
      }
      if (forCarton) {
        final result = await Provider.of<StockProvider>(context, listen: false)
            .onScanCartonProduct(context, code);
        if (!context.mounted) return;
        if (result.success == false) {
          Future.delayed(Duration(seconds: 1), () {
            if (!context.mounted) return;
            if (result.message != null) {
              handleInvalidCode(context, controller, code, result.message);
            } else {
              hasScanned = false;
              controller.start();
            }
          });
        } else {
          if (result.message != null) {
            showToast(result.message ?? '');
          }
          Future.delayed(Duration(seconds: 1), () {
            if (!context.mounted) return;
            navigatePop(context);

            controller.start();
            hasScanned = false;
          });
        }
      } else if (forDamageTransfer) {
        final success = await Provider.of<OrderProvider>(context, listen: false)
            .scannedDamageProduct(code);
        if (success) showToast("Product Scanned Successfully");
        hasScanned = false;
        controller.start();
      } else if (fromStockVerification) {
        final provider =
            Provider.of<StockVerificationProvider>(context, listen: false);
        // If other cartoon check is needed
        // if (provider.cartonId != "0" &&
        //     (provider.selectedStore?.isMainStore ?? false)) {
        //   final splittedCartonId = code.split('-')[2];
        //   if (splittedCartonId != provider.cartonId) {
        //     handleInvalidCarton(
        //         context, controller, splittedCartonId.toInt(), code);
        //     return;
        //   }
        // }

        if (provider.scannedUnits.contains(code)) {
          handleInvalidCode(
              context, controller, code, "Already Scanned Product");
          return;
        }

        final success = provider.onScanProduct(
          context,
          productId,
          code,
          fromStockVerification: fromStockVerification,
        );
        if (!success && context.mounted) {
          handleInvalidCode(context, controller, code);
        } else {
          Future.delayed(Duration(seconds: 1), () {
            if (!context.mounted) return;
            controller.start();
            hasScanned = false;
          });
        }
      } else if (fromTransfer) {
        try {
          log("Scanning for transfer-$productId-$code");

          final result =
              await Provider.of<PackerTransferProvider>(context, listen: false)
                  .scanProduct(
                      context, productId, code, controller, forDamageReceive);

          if (result && context.mounted) {
            controller.dispose();
            Navigator.pop(context, true);
          } else if (context.mounted) {
            await controller.start();
            hasScanned = false;
          }
        } catch (e) {
          if (context.mounted) {
            showToast("Error: $e");
            await controller.start();
            hasScanned = false;
          }
        }
      }
    } catch (e) {
      //

      handleInvalidCode(context, controller, code);

      // await controller.start();
      // rethrow;
    }
  }

  void handleInvalidCarton(BuildContext context,
      MobileScannerController controller, int cartonId, String tag,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: false,
      body: Text("Invalid product for this carton"),
      okTitle: 'Scan the carton',
      okFunc: () async {
        Navigator.pop(context);
        await Provider.of<StockVerificationProvider>(context, listen: false)
            .getCartonInfo(context, cartonId, tag);
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        navigatePop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Any cleanup specific to cart item scanning
    controller.dispose();
  }
}
