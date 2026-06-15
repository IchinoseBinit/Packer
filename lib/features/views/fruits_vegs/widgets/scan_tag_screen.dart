import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/fruits_vegs/widgets/rate_ripeness_widget.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class ScanTagScreen extends BaseScanScreen {
  final ProductModel productModel;
  final Units unit;

  const ScanTagScreen({
    super.key,
    required this.productModel,
    required this.unit,
  }) : super(
          scanTitle: 'Scan Tag',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Tag-${unit.tag}");
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      if (code != unit.tag) {
        throw Exception("Scanned tag does not match the expected tag.");
      }

      //   If we reach here, it means the correct tag was scanned
      //
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RateRipenessWidget(productModel: productModel, unit: unit),
        ),
      );

      await navigatePop(context, true);
    } catch (e) {
      handleInvalidCode(context, controller, code, e.toString());
      return;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Any cleanup specific to cart item scanning
  }
}
