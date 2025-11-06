// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'package:packer/features/views/widgets/show_alert_dialog.dart';

// ignore: must_be_immutable
class DamagedScanScreen extends BaseScanScreen {
  DamagedScanScreen(
      {super.key, required this.showInfo, required this.qr, this.scanRack
      // required this.index,
      })
      : super(
          scanTitle: scanRack! ? "Scan the Rack" : "Scan the Product",
          floatingActionButtonLocation: showInfo
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );

  bool hasScanned = false;
  bool qr = false;
  bool? scanRack;

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
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
          child: scanRack!
              ? null
              : GeneralElevatedButton(
                  title: "Confirm Verification",
                  onPressed: () {
                    final remainingItem = provider.getUnscannedTags();
                    ShowAlertDialog(
                      title: "Confirm",
                      body: Text(qr
                          ? "Product Scanned \n${provider.tagList.join('\n')}"
                          : "Product left \n${remainingItem.join('\n')}"),
                      okFunc: () {
                        if (qr) {
                          provider.markDamaged(provider.tagList, context);
                        } else {
                          provider.markDamaged(remainingItem, context);
                        }
                        navigatePop(context);
                        navigatePop(context);
                      },
                      needCancel: true,
                      cancelFunc: () {
                        navigatePop(context);
                      },
                    ).showAlertDialog(context);
                  },
                ),
        );
      },
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;
    final provider =
        Provider.of<DamageProductController>(context, listen: false);
    try {
      controller.stop();

      HapticFeedback.heavyImpact();

      log("code: $code");
      if (qr) {
        provider.scannedTags(code, context);
        Provider.of<DamageProductController>(context, listen: false)
            .getMessageForNoQr(context, scanRack!, qr);
      } else if (scanRack!) {
        final success = await provider.getProductList(code);

        if (success) {
          navigateReplacement(context,
              route: NavigationConstants.rackProductListScreenRoute);
        }
      } else {
        await provider.postProductTag(code);
        provider.scannedTags(code, context);
        Provider.of<DamageProductController>(context, listen: false)
            .getMessageForNoQr(context, scanRack!, qr);
      }

      if (!scanRack!) {
        final id = code.split("-").first;
        final parsedId = int.tryParse(id);
        if (parsedId == null) {
          handleInvalidCode(context, controller, code);
          return;
        }
      }
      if (context.mounted) {
      } else {
        controller.start();
      }
    } catch (e) {
      handleInvalidCode(context, controller, code);
    } finally {
      hasScanned = false;
      controller.start();
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
  void onDispose(MobileScannerController controller) {}

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<DamageProductController>(context, listen: false).reset();
    Provider.of<DamageProductController>(context, listen: false)
        .getMessageForNoQr(context, scanRack!, qr);
  }
}
