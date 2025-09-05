import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

/// [StockVerificationScanner] : Scanner screen for stock verification | Audit Store
/// 
/// if changeRack is true then it will scan rack code and update rack details
/// 
/// if forCarton is true then it will scan carton code and get carton details
/// 
/// if forProduct is true then it will scan product code then adds tags to scanned units
/// 
class StockVerificationScanner extends BaseScanScreen {
  final bool changeRack;
  final bool forCarton;
  final bool forProduct;

  StockVerificationScanner({
    super.key,
    this.changeRack = false,
    this.forCarton = false,
    this.forProduct = false,
  }) : super(
          scanTitle: forProduct
              ? 'Product Scanner'
              : forCarton
                  ? 'Carton Scanner'
                  : 'Rack Scanner',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );

  bool hasScanned = false;

  /// [handleInvalidCode] : handles invalid code
  /// 
  /// if invalid code is scanned, it will show alert dialog
  /// 
  /// if user click on ok, it will pop alert dialog and restart scanner
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

  /// [completeDialog] : shows complete dialog
  /// 
  /// if user click on ok, it will pop alert dialog and Submit the scanned units to server
  /// 
  /// if user click on cancel, it will pop alert dialog and continue scanning
  Future<bool?> completeDialog(BuildContext context, int scanCount) async {
    return await ShowAlertDialog(
      disableBackground: true,
      body: Text(
        "Are you sure you want to complete verification?\n"
        "Scanned Units: $scanCount",
      ),
      needCancel: true,
      okFunc: () => Navigator.pop(context, true),
      cancelFunc: () {
        Navigator.pop(context, false);
      },
    ).showAlertDialog(context);
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    final provider = Provider.of<StockVerificationProvider>(context);
    if (forProduct || forCarton) {
      if (provider.showCompleteButton()) {
        return GeneralElevatedButton(
          marginH: 16,
          onPressed: () async {
            final provider =
                Provider.of<StockVerificationProvider>(context, listen: false);
            final result =
                await completeDialog(context, provider.scannedUnits.length);
            if (result != true) return;
            if (!context.mounted) return;
            final verifyResult = await provider.onVerify(context);
            if (verifyResult.success) {
              controller.start();
              if (verifyResult.message != null) {
                showToast(verifyResult.message!);
              }
              if ((provider.selectedStore?.isMainStore ?? false) &&
                  context.mounted) {
                navigateReplacement(context,
                    route: NavigationConstants.stockVerificationScannerRoute,
                    extra: {
                      'forCarton': true,
                    });
              }
            } else {
              if (verifyResult.message != null && context.mounted) {
                handleInvalidCode(
                    context, controller, '', verifyResult.message);
              } else {
                controller.start();
                hasScanned = false;
              }
            }
          },
          title: "Complete Verification",
        );
      } else if (provider.showChangeRackButton()) {
        return GeneralElevatedButton(
          marginH: 16,
          onPressed: () async {
            controller.start();
            provider.reset();
            provider.setScanMessage(context);
            navigateReplacement(
              context,
              route: NavigationConstants.stockVerificationScannerRoute,
              extra: {
                'changeRack': true,
              },
            );
          },
          title: "Change Rack",
        );
      }
    }
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      // prevent multiple scans
      if (hasScanned) return;
      hasScanned = true;

      // stop scanner and vibrate for notify user
      controller.stop();
      HapticFeedback.heavyImpact();

      if (forProduct) {
        if (code.contains("carton") || code.contains("rack") || code.contains("basket")) {
          handleInvalidCode(context, controller, code, "Please scan a product code");
          return;
        }
        final result =
            Provider.of<StockVerificationProvider>(context, listen: false)
                .onScanProduct(context, code);
        if (result.success) {
          hasScanned = false;
          controller.start();
          if (result.message != null) {
            showToast(result.message!);
          }
        } else {
          if (result.message != null && context.mounted) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } else if (forCarton) {
        if (!code.contains("carton")) {
          handleInvalidCode(context, controller, code, "Please scan a carton code");
          return;
        }
        final result =
            await Provider.of<StockVerificationProvider>(context, listen: false)
                .setCartonId(context, code);
        if (result.success) {
          hasScanned = false;
          controller.start();
          if (result.message != null) {
            showToast(result.message!);
          }
          if (context.mounted) {
            navigateReplacement(
              context,
              route: NavigationConstants.stockVerificationScannerRoute,
              extra: {
                'forProduct': true,
              },
            );
          }
        } else {
          if (result.message != null && context.mounted) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } else if (changeRack) {
        if (!code.contains("rack")) {
          handleInvalidCode(context, controller, code, "Please scan a rack code");
          return;
        }
        final provider =
            Provider.of<StockVerificationProvider>(context, listen: false);
        final result = provider.onRackScan(context, code);
        if (result.success) {
          hasScanned = false;
          controller.start();
          if (result.message != null) {
            showToast(result.message!);
          }
        } else {
          if (result.message != null) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      } else {
        if (!code.contains("rack")) {
          handleInvalidCode(context, controller, code, "Please scan a rack code");
          return;
        }
        final provider =
            Provider.of<StockVerificationProvider>(context, listen: false);
        final result = provider.onRackScan(context, code);
        if (result.success) {
          hasScanned = false;
          controller.start();
          if (result.message != null) {
            showToast(result.message!);
          }
        } else {
          if (result.message != null) {
            handleInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
            hasScanned = false;
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        handleInvalidCode(context, controller, code, e.toString());
      }
    }
  }

  @override
  void onDispose(MobileScannerController controller) {
    controller.stop();
  }

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<StockVerificationProvider>(context, listen: false)
        .setScanMessage(context);
  }
}
