// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class ProductScannerScreen extends BaseScanScreen {
  ProductScannerScreen({
    super.key,
    required this.productId,
    // required this.index,
  }) : super(
            scanTitle: "Product Scanner",
            floatingActionButtonLocation:
                FloatingActionButtonLocation.endFloat);

  final int productId;

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return FloatingActionButton(
      backgroundColor: AppColors.primaryColor,
      onPressed: () {
        Provider.of<ProductProvider>(context, listen: false)
            .showProductTags(context, productId);
      },
      child: const Icon(Icons.info, color: Colors.white),
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;
    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      log("code: $code");

      final prodId = int.tryParse(code.split('-').first) ?? 0;
      if (prodId != productId) {
        handleInvalidCode(context, controller, code);
        return;
      }

      final success = await Provider.of<ProductProvider>(context, listen: false)
          .scanProduct(context, productId, code);
      if (success && context.mounted) {
        Navigator.pop(context);
      } else {
        controller.start();
      }
    } catch (e) {
      handleInvalidCode(context, controller, code);
    } finally {
      hasScanned = false;
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
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    final message = Provider.of<ProductProvider>(context, listen: false)
        .getMessage(productId);
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }
}
