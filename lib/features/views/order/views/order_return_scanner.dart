import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/profile/provider/order_return_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class OrderReturnScanner extends BaseScanScreen {
  final bool product;
  final bool rack;
  final int productId;
  OrderReturnScanner(
      {this.product = false, this.rack = false, this.productId = 0})
      : super(
            scanTitle: product
                ? "Product Scanner"
                : rack
                    ? "Rack Scanner"
                    : "Basket Scanner");

  // has scanned
  bool hasScanned = false;
  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;
    HapticFeedback.heavyImpact();
    controller.stop();

    try {
      if (product) {
        // split code into productId and match with first
        final productIdString = code.split("-").first;
        if (productIdString != productId.toString()) {
          hanldeInvalidCode(
              context, controller, code, "Invalid QR - Product QR not found");
          return;
        }
        final result =
            await Provider.of<OrderReturnProvider>(context, listen: false)
                .onScanProduct(context, productId, code);
        if (result.success) {
          controller.start();
          hasScanned = false;
          Provider.of<OrderReturnProvider>(context, listen: false)
              .initScannedTagsList();
          navigatePop(context);
        } else {
          if (result.message != null) {
            hanldeInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
          }
        }
      } else if (rack) {
        if (!code.contains("rack")) {
          hanldeInvalidCode(context, controller, code);
          return;
        }
        final result =
            await Provider.of<OrderReturnProvider>(context, listen: false)
                .onScanRack(context, code, productId);
        if (result.success) {
          controller.start();
          hasScanned = false;
          Provider.of<OrderReturnProvider>(context, listen: false)
              .initScannedTagsList();
          Future.delayed(Duration(seconds: 1), () {
            if (!context.mounted) return;
            navigateReplacement(context,
                route: NavigationConstants.orderReturnScannerRoute,
                extra: {"productId": productId, "product": true});
          });
        } else {
          if (result.message != null) {
            hanldeInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
          }
        }
      } else {
        if (!code.contains("basket")) {
          hanldeInvalidCode(context, controller, code);
          return;
        }
        final result =
            await Provider.of<OrderReturnProvider>(context, listen: false)
                .onScanBasket(context, code);
        if (result.success) {
          Provider.of<OrderReturnProvider>(context, listen: false)
              .initScannedTagsList();
          navigateReplacement(context,
              route: NavigationConstants.orderReturnDetailsRoute);
        } else {
          if (result.message != null) {
            hanldeInvalidCode(context, controller, code, result.message);
          } else {
            controller.start();
          }
        }
      }
    } catch (e) {
      hanldeInvalidCode(context, controller, code, e.toString());
    } finally {
      hasScanned = false;
    }
  }

  hanldeInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      body: Text("Invalid QR ${message ?? detectQrMessage(code)}"),
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
    // TODO: implement onScreenCreated
    if (product) {
      Provider.of<OrderReturnProvider>(context, listen: false)
          .getProductIntialMessage(context, productId);
    } else if (rack) {
      Provider.of<OrderReturnProvider>(context, listen: false)
          .getRackIntialMessage(context, productId);
    } else {
      Provider.of<OrderReturnProvider>(context, listen: false)
          .getBasketIntialMessage(context);
    }
  }
}
