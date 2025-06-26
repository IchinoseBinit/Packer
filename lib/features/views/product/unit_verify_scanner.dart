import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class UnitVerifyScanner extends BaseScanScreen {
  final bool productScan;
  final bool showInfo;

  bool hasScanned = false;
  UnitVerifyScanner({
    this.productScan = false,
    this.showInfo = false,
    super.key,
  }) : super(
          scanTitle: productScan ? "Product Scanner" : "Rack Scanner",
          floatingActionButtonLocation: showInfo
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
          showFlash: true,
          showBackButton: true,
        );

  @override
  void onScreenCreated(BuildContext context) {
    if (productScan) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Product Code");
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Rack Code");
    }
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;

    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      log("code for unit verify: $code");

      if (!productScan) {
        if (!code.contains('rack')) {
          handleInvalidCode(context, controller, code);
          return;
        }
        navigatePop(context);
        Future.delayed(
          Durations.medium1,
          () {
            if (!context.mounted) return;
            Provider.of<ProductProvider>(context, listen: false)
                .onRackScan(context, code);
          },
        );
      } else {
        final success =
            await Provider.of<ProductProvider>(context, listen: false)
                .scanProduct(context, code);
        if (success && context.mounted) {
          Navigator.pop(context);
        } else {
          controller.start();
        }
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
        navigatePop(context);
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
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    if (showInfo) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<ProductProvider>(context, listen: false)
              .showProductTags(context);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    final provider = Provider.of<ProductProvider>(context, listen: false);

    return GeneralElevatedButton(
      marginH: 16,
      onPressed: () async {
        controller.stop();
        final scanned = provider.scannedUnits.length;

        if (scanned == 0) {
          return;
        }

        // Show confirmation dialog
        final shouldContinue = await ShowAlertDialog(
          body: Text(
            "Are you sure you want to scan new rack for this product?\n"
            "Scanned Units: $scanned",
          ),
          needCancel: true,
          disableBackground: true,
          okFunc: () => Navigator.pop(context, true),
          cancelFunc: () {
            controller.start();
            Navigator.pop(context, false);
          },
        ).showAlertDialog(context);

        if (shouldContinue != true) return;
        if (!context.mounted) return;
        // showLoading(context);
        provider.completeTagsScan(context);
        navigatePop(context);

        Future.delayed(Durations.medium1, () {
          if (!context.mounted) return;

          // removeLoading(context);
          navigate(
            context,
            route: NavigationConstants.unitVerifyScannerRoute,
          );
        });
      },
      title: "Scan New Rack",
    );
  }
}
