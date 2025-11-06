import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/receive_baskets/controller/receive_basket_controller.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class ReceiveBasketScanner extends BaseScanScreen {
  final bool scanIdentifier;
  ReceiveBasketScanner({super.key, this.scanIdentifier = false})
      : super(scanTitle: scanIdentifier ? "Scan Identifier" : "Scan Basket");

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;
      controller.stop();

      HapticFeedback.heavyImpact();

      if (scanIdentifier) {
        final value =
            Provider.of<ReceiveBasketController>(context, listen: false)
                .onScanIdentifier(context, code);
        if (value.success && context.mounted) {
          navigateReplacement(context,
              route: NavigationConstants.receiveBasketListRoute);
          if (value.message != null) {
            showToast(value.message!);
          }
        } else if (context.mounted) {
          await Future.delayed(const Duration(seconds: 1));
          if (value.message == null) {
            controller.start();
          } else {
            handleInvalidQrCode(context, controller, code, value.message);
          }
        }
      } else {
        if (!code.contains("basket")) {
          handleInvalidQrCode(context, controller, code);
          return;
        }

        final value =
            Provider.of<ReceiveBasketController>(context, listen: false)
                .onScanBasket(context, code);
        if (value.success && context.mounted) {
          Navigator.pop(context);
          if (value.message != null) {
            showToast(value.message!);
          }
        } else if (context.mounted) {
          await Future.delayed(const Duration(seconds: 1));
          if (value.message == null) {
            controller.start();
          } else {
            handleInvalidQrCode(context, controller, code, value.message);
          }
        }
      }
    } catch (e) {
      handleInvalidQrCode(context, controller, code);
    } finally {
      hasScanned = false;
    }
  }

  void handleInvalidQrCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () async {
        navigatePop(context);
        await controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    if (scanIdentifier) {
      Provider.of<ReceiveBasketController>(context, listen: false)
          .getMessageForIdentifier(context);
    } else {
      Provider.of<ReceiveBasketController>(context, listen: false)
          .getMessageForBasket(context);
    }
  }
}
