import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class CartonScanScreen extends BaseScanScreen {
  final int? cartonId;
  final bool fromVerification;
  final bool isMainStoreAudit;
  final String? cartonCode;
  final String? tag;
  CartonScanScreen({
    super.key,
    this.cartonId,
    this.fromVerification = false,
    this.isMainStoreAudit = false,
    this.cartonCode,
    this.tag,
  }) : super(
          scanTitle: 'Carton Scanner',
          showFlash: true,
          showBackButton: true,
        );

  bool _isProcessing = false;

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Carton Code");
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    if (isMainStoreAudit) {
      return GeneralElevatedButton(
        marginH: 16,
        title: 'Change Rack',
        onPressed: () {
          navigateReplacement(context,
              route: NavigationConstants.stockRackScanScreenRoute,
              extra: {
                'changeRack': false,
              });
        },
      );
    }
    return SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await controller.stop();
      HapticFeedback.heavyImpact();

      showLoading(context);
      log("Carton Code: $code");

      if (!code.toLowerCase().contains("carton")) {
        if (context.mounted) {
          handleInvalidCode(context, controller, code);
        }
        return;
      }

      bool result = false;
      bool back = false;

      if (isMainStoreAudit) {
        await Provider.of<StockVerificationProvider>(context, listen: false)
            .onScanCarton(context, code);
        removeLoading(context);
        navigateReplacement(context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              'fromStockVerification': true,
            });
        return;
      } else if (!fromVerification &&
          cartonCode != null &&
          code.toLowerCase() == cartonCode!.toLowerCase()) {
        result =
            await Provider.of<StockVerificationProvider>(context, listen: false)
                .singleVerification(context, cartonId!, tag!);
      } else if (!fromVerification && context.mounted) {
        result = await Provider.of<StockProvider>(context, listen: false)
            .onScanCarton(context, code, cartonId: cartonId);
      } else if (fromVerification && context.mounted) {
        await Provider.of<StockVerificationProvider>(context, listen: false)
            .onScanCarton(context, code, cartonCode: cartonCode);
        removeLoading(context);
        return;
      }

      if (!result && context.mounted) {
        removeLoading(context);
        handleInvalidCode(context, controller, code);
      } else if (context.mounted) {
        removeLoading(context);
        // Optionally navigate back or show success message
        // if (back) {
        //   navigatePop(context, true);
        // }
      }
    } catch (e) {
      if (context.mounted) {
        handleInvalidCode(context, controller, code, e.toString());
      }
    } finally {
      _isProcessing = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    removeLoading(context);
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
    // Cleanup if needed
  }
}
