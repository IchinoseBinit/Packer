import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class TrolleyScanScreen extends BaseScanScreen {
  final int productId;

  TrolleyScanScreen({required this.productId})
      : super(
            scanTitle: "Trolley Item Scanner",
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat);

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return FloatingActionButton(
      backgroundColor: AppColors.primaryColor,
      onPressed: () {
        Provider.of<StockProvider>(context, listen: false)
            .showTrolleyProductTags(context, productId);
      },
      child: const Icon(Icons.list, color: Colors.white),
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;
    controller.stop();

    try {
      HapticFeedback.heavyImpact();
      final value = await Provider.of<StockProvider>(context, listen: false)
          .onScanTrolleyItems(context, productId, code);
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
          handleInvalidCode(context, controller, code, value.message);
        }
      }
    } catch (e) {
      handleInvalidCode(context, controller, code);
    } finally {
      hasScanned = false;
    }
  }

  // handleInvalidCode
  void handleInvalidCode(
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
    Provider.of<StockProvider>(context, listen: false)
        .getMessageForTrolleyItem(context, productId);
  }
}
