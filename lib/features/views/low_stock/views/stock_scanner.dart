import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

/// [StockScanner] is a initial step for stock filling
/// 
/// if forProduct is false then it will scan carton code and get carton details
/// 
/// if forProduct is true; productId is compulsory and it will scan product 
/// Till the required quantity is not scanned it will keep scanning
class StockScanner extends BaseScanScreen {
  final bool forProduct;
  final int productId;

  StockScanner({
    this.forProduct = false,
    this.productId = 0,
  }) : super(
          scanTitle: forProduct ? 'Product Scanner' : 'Carton Scanner',
          showBackButton: true,
          showFlash: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  bool hasScanned = false;
  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
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

      // if for product is true
      if (forProduct) {
        // if scanned code is not of the same product then show alert dialog
        if (code.split("-").first != productId.toString()) {
          handleInvalidCode(context, controller, code, "Please scan product code");
          return;
        }

        // gets ScanResult from provider where the logic is implemented
        final value = await Provider.of<StockProvider>(context, listen: false)
            .checkItemQr(
          context,
          code,
        );

        // if result is successful; is show toast if any message is available and navigate back
        if (value.success && context.mounted) {
          controller.start();
          hasScanned = false;

          if (value.message != null) {
            showToast(value.message!);
          }
          navigatePop(context);
        } 
        // if result is not successful; is show alert dialog if any message is available OR start scanning again
        else if (context.mounted) {
          if (value.message != null) {
            handleInvalidCode(context, controller, code, value.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } 
      // if upper condition is not met then it will scan carton code
      else {
        // if scanned code is not of the same carton then show alert dialog
        if (!code.contains("carton")) {
          handleInvalidCode(context, controller, code, "Please scan carton code");
          return;
        }

        // gets ScanResult from provider where the logic is implemented
        final result = await Provider.of<StockProvider>(context, listen: false)
            .lowStockCartonScan(context, code);

        // if result is successful; is show toast if any message is available
        if (result.success) {
          controller.start();
          hasScanned = false;
          if (result.message != null) {
            showToast(result.message!);
          }
        } 
        // if result is not successful; is show alert dialog if any message is available OR start scanning again
        else {
          if (result.message != null && context.mounted) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      }
    } catch (e) {
      // if exception occurs; is show alert dialog if any message is available
      if (context.mounted) {
        handleInvalidCode(context, controller, code, e.toString());
      }
    }
  }

  // handle invalid QR code or custom error message
  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    // show alert dialog and when user tap ok then it will start scanning again
    // if message is null then it is invalid QR code
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    // set Initial message for scanner
    if (!forProduct) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Carton code");
    } 
  }
}
