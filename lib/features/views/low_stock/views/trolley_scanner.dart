import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/scan/scan_screen.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'package:packer/features/views/widgets/show_alert_dialog.dart';

/// [TrolleyScanner] is for trolley items scanning BASKET,PRODUCT
/// 
/// if changeBasket and forProduct both is false then it is called from collected product screen
/// and it will scan basket code then navigate to trolley item screen
/// 
/// if changeBasket is true then it is called from trolley_item screen
/// and it will scan basket code then navigate back to trolley item screen
/// 
/// if forProduct is true then it is compulsory to pass productId
/// and it will scan product code till scanned count is equal to quantity

class TrolleyScanner extends BaseScanScreen {
  TrolleyScanner({
    super.key,
    this.changeBasket = false,
    this.productId,
    this.forProduct = false,
  }) : super(
          scanTitle: forProduct ? 'Product Scanner' : 'Basket Scanner',
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          showBackButton: true,
          showFlash: true,
        );

  final bool changeBasket;
  final int? productId;
  final bool forProduct;

  bool hasScanned = false;

  // handle invalid QR code or custom error message
  void handleInvalidQr(
      BuildContext context, MobileScannerController controller, String code,
      {String? message}) {
    // if message is null then it is invalid QR code
    // it show alert dialog and when user tap ok then it will start scanning again
    ShowAlertDialog(
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    // if scanning product then it will show floating button to show product tags 
    // which tags are pending to scan and which are already scanned
    if (forProduct) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<StockProvider>(context, listen: false)
              .showTrolleyProductTags(context, productId!);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      // if already scanned then return
      if (hasScanned) return;
      hasScanned = true;

      // stop scanning once code is detected
      controller.stop();

      // notify user with heavy vibration
      HapticFeedback.heavyImpact();

      // if for product then it will scan product code
      if (forProduct) {
        // gets ScanResult from provider where the logic is implemented
        final value = await Provider.of<StockProvider>(context, listen: false)
            .onScanTrolleyItems(
          context,
          productId!,
          code,
        );
        // if result is successful; is show toast if any message is available and navigate back
        if (value.success && context.mounted) {
          // controller.start();
          hasScanned = false;
          if (value.message != null) {
            showToast(value.message!);
          }
          Navigator.pop(context);
        } 
        // if result is not successful; is show alert dialog if any message is available OR start scanning again
        else if (context.mounted) {
          if (value.message != null) {
            handleInvalidQr(context, controller, code, message: value.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } 
      // if upper condition is not met then it will scan basket code
      else {
        // gets ScanResult from provider where the logic is implemented
        final value = await Provider.of<StockProvider>(context, listen: false)
            .checkBasketQr(context, code);
        // if result is successful; is show toast if any message is available
        // also check if changeBasket is true then navigate back to trolley item screen
        // else navigate to trolley item screen
        if (value.success && context.mounted) {
          hasScanned = false;
          // controller.start();

          if (value.message != null) {
            showToast(value.message!);
          }

          if (!changeBasket) {
            navigateReplacement(context,
                route: NavigationConstants.trolleyItemScreenRoute);
          } else {
            // basket change
            navigatePop(context);
          }
        } 
        // if result is not successful; is show alert dialog if any message is available OR start scanning again
        else if (context.mounted) {
          if (value.message != null) {
            handleInvalidQr(context, controller, code, message: value.message);
          } else {
            hasScanned = false;
            controller.start();
          }
        }
      }
    } catch (e) {
      // if exception occurs; is show alert dialog if any message is available
      if (context.mounted) {
        handleInvalidQr(context, controller, code, message: e.toString());
      }
    }
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    // set Initial message for scanner
    if (forProduct) {
      Provider.of<StockProvider>(context, listen: false)
          .getMessageForTrolleyItem(context, productId!);
    }else{
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Basket Code");
    }
  }
}
