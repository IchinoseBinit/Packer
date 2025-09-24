import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/inventory_transfer_request/provider/inventory_transfer_request_controller.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class InventoryTransferRequestScanner extends BaseScanScreen {
  InventoryTransferRequestScanner({
    super.key,
    this.scanLocal = false,
    this.scanBasket = false,
  }) : super(
            scanTitle: scanBasket ? "Basket Scanner" : "Product Scanner",
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat);

  final bool scanLocal;
  final bool scanBasket;

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    if (scanLocal) {
      return Consumer<InventoryTransferRequestController>(
        builder: (context, value, child) => value.localSelectedItem == null
            ? SizedBox.shrink()
            : FloatingActionButton(
                backgroundColor: AppColors.primaryColor,
                onPressed: () async {
                  Provider.of<InventoryTransferRequestController>(context,
                          listen: false)
                      .showProductTags(context);
                },
                child: const Icon(Icons.info, color: Colors.white),
              ),
      );
    }
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();

      HapticFeedback.heavyImpact();

      if (scanBasket) {
        final scanResult =
            await Provider.of<InventoryTransferRequestController>(context,
                    listen: false)
                .handleBasketScan(context, code);
        if (scanResult.success && context.mounted) {
          if (scanResult.message != null) {
            showToast(scanResult.message!);
          }
        } else if (context.mounted) {
          if (scanResult.message == null) {
            controller.start();
            hasScanned = false;
          } else {
            handleInvalidCode(context, controller, code, scanResult.message);
          }
        }
      } else if (scanLocal) {
        final scanResult =
            await Provider.of<InventoryTransferRequestController>(context,
                    listen: false)
                .handleLocalProductScan(context, code);

        if (scanResult.success && context.mounted) {
          navigatePop(context);
          if (scanResult.message != null) {
            showToast(scanResult.message!);
          }
        } else if (context.mounted) {
          if (scanResult.message == null) {
            controller.start();
            hasScanned = false;
          } else {
            handleInvalidCode(context, controller, code, scanResult.message);
          }
        }
      } else {
        final scanResult =
            await Provider.of<InventoryTransferRequestController>(context,
                    listen: false)
                .handleProductScan(context, code);
        await Future.delayed(const Duration(milliseconds: 300));
        if (scanResult.success && context.mounted) {
          Navigator.pop(context);
          if (scanResult.message != null) {
            showToast(scanResult.message!);
          }
        } else if (context.mounted) {
          if (scanResult.message == null) {
            controller.start();
            hasScanned = false;
          } else {
            handleInvalidCode(context, controller, code, scanResult.message);
          }
        }
      }
    } catch (e) {
      handleInvalidCode(context, controller, code, e.toString());
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      // canDismiss: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        navigatePop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) {}

  @override
  void onScreenCreated(BuildContext context) {
    if (scanBasket) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Basket Code");
    } else if (scanLocal) {
      Provider.of<InventoryTransferRequestController>(context, listen: false)
          .getLocalProductScanMessage(context);
    } else {
      Provider.of<InventoryTransferRequestController>(context, listen: false)
          .getProductScanMessage(context);
    }
  }
}
