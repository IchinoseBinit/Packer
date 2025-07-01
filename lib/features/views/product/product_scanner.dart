// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class UnitProductScannerScreen extends BaseScanScreen {
  UnitProductScannerScreen({
    super.key,
    required this.showInfo,
    // required this.index,
  }) : super(
          scanTitle: "Product Scanner",
          floatingActionButtonLocation: showInfo
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );

  bool hasScanned = false;

  final bool showInfo;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    if (showInfo) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<ProductProvider>(context, listen: false)
              .showProductTagsDialog(context);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    final provider = Provider.of<ProductProvider>(context, listen: false);

    return Column(
      spacing: 12.h,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // if (provider.unitVerifyModels.length < ProductProvider.maxProductCount -1)
        Consumer<ProductProvider>(builder: (context, value, _) {
          if (value.canScanNewProduct()) {
            return GeneralElevatedButton(
              marginH: 16,
              onPressed: () async {
                controller.stop();
                // final scanned = provider.unitVerifyModels.length;

                // if (scanned >= ProductProvider.maxProductCount - 1) {
                //   ErrorHandler.alertDialog(context, "You can only scan ${ProductProvider.maxProductCount} products");
                //   controller.start();
                //   return;
                // }

                // Show confirmation dialog
                final shouldContinue = await ShowAlertDialog(
                  body: Text("Are you sure you want to scan new product?\n"
                      // "Scanned Units: $scanned\n"
                      // "Total Tags: ${provider.unitVerifyModel?.productAvailability?.productUnits.length}\n"
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
                controller.start();
                provider.switchToNextProduct(context);
                // navigatePop(context);

                // Future.delayed(Durations.medium1, () {
                //   if (!context.mounted) return;

                //   // removeLoading(context);
                //   // navigateReplacement(
                //   //   context,
                //   //   route: NavigationConstants.unitVerifyScannerRoute,
                //   //   extra: {
                //   //     'reScan': true,
                //   //   },
                //   // );
                // });
              },
              title: "Scan New Product",
            );
          }
          return SizedBox.shrink();
        }),
        GeneralElevatedButton(
          marginH: 16,
          onPressed: () async {
            controller.stop();
            final scanned = provider.scannedUnits.length;

            if (scanned == 0) {
              ErrorHandler.alertDialog(context, "No tags scanned");
              controller.start();
              return;
            }

            // Show confirmation dialog
            final shouldContinue = await ShowAlertDialog(
              body: Text("Are you sure you want to scan new rack?\n"
                  // "Scanned Units: $scanned\n"
                  // "Total Tags: ${provider.unitVerifyModel?.productAvailability?.productUnits.length}\n"
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
            provider.completeScanningSession(context);
          },
          title: "Re-Rack",
        ),
      ],
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

      // check by spliting code
      final id = code.split("-").first;
      // try parsing id
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        handleInvalidCode(context, controller, code);
        return;
      }

      final success = await Provider.of<ProductProvider>(context, listen: false)
          .handleProductScan(context, code);
      if (success && context.mounted) {
        controller.start();
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
    final message =
        Provider.of<ProductProvider>(context, listen: false).getScanMessage();
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }
}
