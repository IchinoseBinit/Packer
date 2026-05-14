import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/inventory_transfer_main_store/controller/inventory_transfer_controller.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class InventoryTransferScanner extends BaseScanScreen {
  InventoryTransferScanner({
    super.key,
    this.scanBasket = false,
    this.scanCarton = false,
  }) : super(
          scanTitle: scanBasket
              ? "Basket Scanner"
              : scanCarton
                  ? "Carton Scanner"
                  : "Product Scanner",
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  final bool scanBasket;
  final bool scanCarton;

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    if (!scanBasket && !scanCarton) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<InventoryTransferController>(context, listen: false)
              .showProductTags(context);
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
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();

      HapticFeedback.heavyImpact();

      if (scanBasket) {
        final scanResult = await Provider.of<InventoryTransferController>(
                context,
                listen: false)
            .handleBasketScan(context, code);

        if (scanResult.success && context.mounted) {
          if (scanResult.message != null) {
            showToast(scanResult.message!);
          }
          navigateReplacement(context,
              route: NavigationConstants.inventoryTransferItemsRoute);
        } else if (context.mounted) {
          if (scanResult.message == null) {
            controller.start();
            hasScanned = false;
          } else {
            handleInvalidCode(context, controller, code, scanResult.message);
          }
        }
      } else if (scanCarton) {
        final scanResult = await Provider.of<InventoryTransferController>(
                context,
                listen: false)
            .handleCartonScan(context, code);

        if (scanResult.success && context.mounted) {
          if (scanResult.message != null) {
            showToast(scanResult.message!);
          }
          controller.start();
          navigateReplacement(context,
              route: NavigationConstants.inventoryTransferScannerRoute);
        } else if (context.mounted) {
          if (scanResult.message == null) {
            controller.start();
            hasScanned = false;
          } else {
            handleInvalidCode(context, controller, code, scanResult.message);
          }
        }
      } else {
        final scanResult = await Provider.of<InventoryTransferController>(
                context,
                listen: false)
            .handleProductScan(context, code);

        if (scanResult.success && context.mounted) {
          if (scanResult.message != null) {
            showToast(scanResult.message!);
          }
          navigatePop(context);
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

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    // TODO: implement onScreenCreated
    if (scanBasket) {
      Provider.of<InventoryTransferController>(context, listen: false)
          .getBasketScanMessage(context);
    } else if (scanCarton) {
      Provider.of<InventoryTransferController>(context, listen: false)
          .getCartonScanMessage(context);
    } else {
      Provider.of<InventoryTransferController>(context, listen: false)
          .getProductScanMessage(context);
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
}
