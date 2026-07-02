import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/profile/provider/rack_update_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class UpdateRackScreen extends BaseScanScreen {
  final int? productId;

  bool hasScanned = false;
  UpdateRackScreen({
    super.key,
    this.productId,
  }) : super(
          scanTitle: productId != null ? "Rack Scanner" : "",
          showFlash: true,
          showBackButton: true,
        );
  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;
    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      final updateRackProvider =
          Provider.of<RackUpdateProvider>(context, listen: false);

      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      if (productId != null) {
        await updateRackProvider.updateRack(context, code, productId!);
        controller.start();
        return;
      } else if (homeProvider.isMainStore()) {
        await updateRackProvider.callCartonInfoApi(context, code);
        controller.start();
      } else {
        await updateRackProvider.getProductId(context, code);
        controller.start();
      }
    } catch (e) {
      handleInvalidCode(context, controller, code);
    } finally {
      hasScanned = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code) {
    removeLoading(context);
    ShowAlertDialog(
      disableBackground: true,
      body: Text("Invalid QR ${detectQrMessage(code)}"),
      okFunc: () async {
        navigatePop(context);
        await controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) async {
    await controller.stop();
    await controller.dispose();
  }

  @override
  void onScreenCreated(BuildContext context) {
    if (productId != null) {
      return;
    }
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    if (homeProvider.isMainStore()) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Carton Code");
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Product Code");
    }
  }
}
