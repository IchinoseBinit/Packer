// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class DamagedScanScreen extends BaseScanScreen {
  DamagedScanScreen({super.key, required this.showInfo, required this.qr
      // required this.index,
      })
      : super(
          scanTitle: "Scan the Product",
          floatingActionButtonLocation: showInfo
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );

  bool hasScanned = false;
  bool qr = false;

  final bool showInfo;

  @override
  Widget? buildFloatingButton(
    BuildContext context,
    MobileScannerController controller,
  ) {
    if (showInfo) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () {
          Provider.of<ProductProvider>(context, listen: false)
              .showProductTagsDialog(context);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }

    return Consumer<DamageProductController>(
      builder: (context, provider, _) {
        return GeneralElevatedButton(
          title: qr ? "Confirm Verification" : "Check Unscanned Tags",
          onPressed: () {
            if (qr) {
              ShowAlertDialog(
                title: "Confirm",
                body: Text("Scan all products.${provider.tagList.join('\n')}"),
                okFunc: () {
                  provider.markDamaged(provider.tagList);
                  navigatePop(context);
                },
                cancelFunc: () {
                  navigatePop(context);
                },
              ).showAlertDialog(context);
            } else {
              final unscanned = provider.getUnscannedTags();

              ShowAlertDialog(
                title: "Unscanned Tags",
                body: Text(
                  unscanned.isEmpty
                      ? "All tags scanned!"
                      : "Missing tags:\n\n${unscanned.join('\n')}",
                ),
                okFunc: () {
                  navigatePop(context);
                },
              ).showAlertDialog(context);
            }
          },
        );
      },
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
      if (qr) {
        Provider.of<DamageProductController>(context, listen: false)
            .scannedTags(code);
      } else {
        await Provider.of<DamageProductController>(context, listen: false)
            .postProductTag(code);
      }

      // check by spliting code
      final id = code.split("-").first;
      final parsedId = int.tryParse(id);
      if (parsedId == null) {
        handleInvalidCode(context, controller, code);
        return;
      }

      if (context.mounted) {
        final provider =
            Provider.of<DamageProductController>(context, listen: false);
        if (!qr) provider.scannedTags(code);

        controller.start();
        ShowAlertDialog(
          title: "Do you want to scan other item",
          body: Text("ssssss"),
          okFunc: () {
            navigatePop(context);
          },
          needCancel: true,
          cancelFunc: () async {
            navigatePop(context);

            showLoading(context);
            if (!qr) {
              final remainingItem = provider.getUnscannedTags();

              removeLoading(context);
              provider.markDamaged(remainingItem);
              navigatePop(context);
            } else {
              navigatePop(context);
            }
          },
        ).showAlertDialog(context);
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
    // controller.dispose();
  }

  @override
  void onScreenCreated(BuildContext context) {
    final message = Provider.of<ProductProvider>(context, listen: false)
        .getScanMessage(isVerificationScan: showInfo);
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }
}
