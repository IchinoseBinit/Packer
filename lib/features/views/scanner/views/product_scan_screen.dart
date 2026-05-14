import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
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
  bool forDamageRequest;
  bool forExpiredProducts = false;
  List<String>? tags;

  // if time out gap is needed after scanning a code to avoid multiple scans of product
  // if gap is between 2 scans is hold for more than 5 seconds then ask user to extend the gap time to 10 second and
  // then gap become 10 second then go back and scan rack once again restart same process again if user want to continue with 10 second gap or not
  bool needGapTime = false;

  ProductScanScreen({
    super.key,
    required this.productId,
    this.fromStockVerification = false,
    this.cartonId,
    this.fromTransfer = false,
    this.forCarton = false,
    this.forDamageTransfer = false,
    this.forDamageReceive = false,
    this.forDamageRequest = false,
    this.forExpiredProducts = false,
    this.tags,
    this.needGapTime = false,
  }) : super(
          scanTitle: 'Product Scanner',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation:
              fromTransfer || forCarton || forExpiredProducts
                  ? FloatingActionButtonLocation.endFloat
                  : FloatingActionButtonLocation.centerFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    log("aaaaaaaaaaa : needGapTime - $needGapTime");
    if (forCarton) {
      Provider.of<StockProvider>(context, listen: false)
          .getMessageForCartonProduct(context);
    } else if (fromStockVerification) {
      Provider.of<StockVerificationProvider>(context, listen: false)
          .getMessage(context);
    } else if (!fromTransfer) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Product Code");
    } else if (forDamageRequest) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Damage Product Request");
    }

    //
    if (needGapTime) {
      _startScanGapCountdown(context);
    }
  }

  bool isProcessing = false;
  List<String> scannedCodes = [];

  Timer? _scanGapTimer;

  late final ValueNotifier<int> _scanGapTimerData = ValueNotifier(10);

  // list of scanned units

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    // if for expired product and has tags show floating button to show tags
    if (forExpiredProducts && tags != null && tags!.isNotEmpty) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<ScanMessageProvider>(context, listen: false)
              .setMessage(context, "Scanned Tags:\n${tags!.join('\n')}");
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }

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

    if (forDamageRequest) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.h),
        child: GeneralElevatedButton(
          onPressed: () async {
            final productIds =
                Provider.of<DamageProductController>(context, listen: false)
                    .damageProducts;
            ShowAlertDialog(
              title: "Are you Sure?",
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Scanned Products:"),
                  const SizedBox(height: 8),
                  ...productIds.map((id) => Text("• $id")),
                ],
              ),
              okFunc: () async {
                await navigatePop(context);
                if (!context.mounted) return;
                await controller.stop();
                if (!context.mounted) return;
                navigateReplacement(
                  context,
                  route: NavigationConstants.scanRackRoute,
                  extra: {
                    'forDamageRequest': true,
                  },
                );
              },
              needCancel: true,
              cancelFunc: () => Navigator.pop(context),
            ).showAlertDialog(context);
          },
          title: "Submit Request",
        ),
      );
    }
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
  Widget buildTimer(BuildContext context, MobileScannerController controller) {
    log("needGapTime: $needGapTime");
    if (!needGapTime) return const SizedBox.shrink();

    return ValueListenableBuilder<int?>(
      valueListenable: _scanGapTimerData,
      builder: (context, timerData, _) {
        if (timerData == null) return const SizedBox.shrink();

        return Row(
          spacing: 8,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    ((timerData < 5) ? AppColors.primaryColor : Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(Icons.alarm, color: Colors.white),
                  Text(
                    "$timerData",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            // Show extend button if canExtend is true and not already extended
            if (timerData < 5)
              InkWell(
                onTap: () => _extendScanGapTimer(context),
                child: Container(
                  height: 36.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Need more time?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();
      HapticFeedback.heavyImpact();

      if (tags != null) {
        //
        log("tags: ${tags.toString()} , $code");

        if (tags!.isEmpty) {
          if (needGapTime) {
            _startScanGapCountdown(context);
          }
          await handleInvalidCode(context, controller, code,
              "All tags are already scanned, please press 'Confirm transfer' ");

          return;
        }

        if (!tags!.contains(code)) {
          if (needGapTime) {
            _startScanGapCountdown(context);
          }
          //
          await handleInvalidCode(context, controller, code,
              "You have scanned: \n$code. \n To scan:\n ${tags?.join('\n')} ");
          return;
        }
      }

      if (code.contains("carton") ||
          code.contains("rack") ||
          code.contains("basket")) {
        if (needGapTime) {
          _startScanGapCountdown(context);
        }
        await handleInvalidCode(
            context, controller, code, "Please scan a product code");
        return;
      }

      // split code to get product id
      if (productId > 0) {
        final list = code.split('-');
        final prodId = int.tryParse(list.first) ?? 0;
        if (prodId != productId) {
          if (needGapTime) {
            _startScanGapCountdown(context);
          }
          await handleInvalidCode(context, controller, code,
              "You have scanned $prodId but actual product should be $productId");
          return;
        }
      }

      if (forCarton) {
        //
        List<String> needToScanProductList =
            Provider.of<StockProvider>(context, listen: false)
                .getTagsRemaining(true);

        if (!needToScanProductList.contains(code)) {
          await handleInvalidCode(context, controller, code,
              "You have scanned: \n$code. \n To scan:\n ${needToScanProductList.join('\n')} ");
          return;
        }

        final result = await Provider.of<StockProvider>(context, listen: false)
            .onScanCartonProduct(context, code);
        if (!context.mounted) return;
        if (result.success == false) {
          Future.delayed(Duration(seconds: 1), () async {
            if (!context.mounted) return;
            if (result.message != null) {
              await handleInvalidCode(
                  context, controller, code, result.message);
            } else {
              hasScanned = false;
              controller.start();
            }
          });
        } else {
          if (result.message != null) {
            showToast(result.message ?? '');
          }
          Future.delayed(Duration(seconds: 1), () async {
            if (!context.mounted) return;
            navigatePop(context);

            controller.start();
            hasScanned = false;
          });
        }
      } else if (forDamageTransfer) {
        final success = await Provider.of<OrderProvider>(context, listen: false)
            .scannedDamageProduct(code, context, expired: forExpiredProducts);
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
          await handleInvalidCode(
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
          await handleInvalidCode(context, controller, code);
        } else {
          Future.delayed(Duration(seconds: 1), () async {
            if (!context.mounted) return;
            await controller.start();
            hasScanned = false;
          });
        }
      } else if (forDamageReceive && fromTransfer) {
        try {
          log("Scanning for transfer forDamageReceive -$productId-$code");

          final result =
              await Provider.of<PackerTransferProvider>(context, listen: false)
                  .scanProduct(context, productId, code, controller,
                      (forDamageReceive && fromTransfer));

          if (result.success && context.mounted) {
            await controller.stop();

            if (!context.mounted) return;
            if (needGapTime) {
              _startScanGapCountdown(context);
              if (!context.mounted) return;
            }

            await controller.dispose();

            if (!context.mounted) return;

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
      } else if (fromTransfer) {
        List<String> needToScanProductList =
            Provider.of<PackerTransferProvider>(context, listen: false)
                .getTagsRemaining(context, productId, true);

        if (!needToScanProductList.contains(code)) {
          //
          if (needGapTime) {
            _startScanGapCountdown(context);
          }
          //
          await handleInvalidCode(context, controller, code,
              "You have scanned: \n$code. \n To scan:\n ${needToScanProductList.join('\n')} ");
          return;
        }

        try {
          log("Scanning for transfer-$productId-$code");

          final result =
              await Provider.of<PackerTransferProvider>(context, listen: false)
                  .scanProductForInventoryTransfer(context, productId, code);

          if (result.success && context.mounted) {
            if (!context.mounted) return;
            if (needGapTime) {
              _startScanGapCountdown(context);
              if (!context.mounted) return;
            }

            Navigator.pop(context, true);
            if (result.message != null) {
              showToast(result.message ?? '');
            }
          } else if (context.mounted) {
            if (needGapTime) {
              _startScanGapCountdown(context);
            }

            if (result.message != null) {
              await handleInvalidCode(
                  context, controller, code, result.message);
            } else {
              await controller.start();
              hasScanned = false;
            }
          }
        } catch (e) {
          if (needGapTime) {
            _startScanGapCountdown(context);
          }
          if (context.mounted) {
            showToast("Error: $e");
            await controller.start();
            hasScanned = false;
          }
        }
      } else if (forDamageRequest) {
        final provider =
            Provider.of<DamageProductController>(context, listen: false);
        bool success = provider.setDamageProducts(code, context);
        if (success) {
          showToast("Product Scanned Successfully");
          hasScanned = false;
          controller.start();
        } else {
          hasScanned = false;
          controller.start();
        }
      }
    } catch (e) {
      //

      if (!context.mounted) return;
      //
      if (needGapTime) {
        _startScanGapCountdown(context);
      }
      //
      await handleInvalidCode(context, controller, code);

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

  Future handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) async {
    await ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        navigatePop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
    return;
  }

  @override
  void onDispose(MobileScannerController controller) {
    _scanGapTimer?.cancel();
    _scanGapTimerData.dispose();
    // Any cleanup specific to cart item scanning
  }

  void _startScanGapCountdown(BuildContext context) {
    _scanGapTimer?.cancel();

    final scanGapTime = Provider.of<HomeProvider>(context, listen: false)
            .packerSummary
            ?.scanGapTime ??
        10;

    _scanGapTimerData.value = scanGapTime;

    _scanGapTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentData = _scanGapTimerData.value;

      if (currentData <= 1) {
        timer.cancel();

        _scanGapTimerData.value = 0;

        Navigator.pop(context);
        return;
      }
      _scanGapTimerData.value = currentData - 1;
    });
  }

  void _extendScanGapTimer(BuildContext context) {
    _startScanGapCountdown(context);
  }
}
