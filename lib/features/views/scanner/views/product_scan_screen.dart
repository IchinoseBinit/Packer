import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'base_scan_screen.dart';

class ProductScanScreen extends BaseScanScreen {
  final int productId;
  bool hasScanned = false;
  bool fromStockVerification = false;
  int? cartonId;
  bool fromTransfer = false;

  ProductScanScreen({
    super.key,
    required this.productId,
    this.fromStockVerification = false,
    this.cartonId,
    this.fromTransfer = false,
  }) : super(
          scanTitle: 'Product Scanner',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: fromTransfer
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    if (!fromTransfer) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage(context, "Scan Product Code");
    }
  }

  bool isProcessing = false;
  List<String> scannedCodes = [];

  // list of scanned units

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    if (fromTransfer) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          Provider.of<PackerTransferProvider>(context, listen: false)
              .showProductTags(context, productId);
        },
        child: const Icon(Icons.info, color: Colors.white),
      );
    }
    final provider = Provider.of<StockVerificationProvider>(context);

    return GeneralElevatedButton(
      marginH: 16,
      onPressed: () async {
        controller.stop();
        final total = provider.selectedStockItem?.productUnits.length ?? 0;
        final scanned = provider.scannedUnits.length;

        if (scanned < total) {
          // Show confirmation dialog
          final shouldContinue = await ShowAlertDialog(
            body: Text(
              "Are you sure you want to complete verification?\n"
              "Scanned Units: $scanned\nTotal Units: $total",
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
        }
        if (!context.mounted) return;
        showLoading(context);
        final success =
            await provider.onVerify(productId, provider.scannedUnits.toList());
        if (!context.mounted) return;

        removeLoading(context);

        if (!context.mounted) return;
        if (success) {
          controller.dispose();
          Navigator.pop(context, true);
        } else {
          ShowAlertDialog(
            disableBackground: true,
            body: const Text("Verification failed. Try again."),
            okFunc: () {
              Navigator.pop(context);
              controller.start();
            },
          ).showAlertDialog(context);
        }
      },
      title: "Complete Verification",
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();
      HapticFeedback.heavyImpact();

      // split code to get product id
      final list = code.split('-');
      final prodId = int.tryParse(list.first) ?? 0;
      if (cartonId != null) {
        final splittedCartonId = int.tryParse(list[2]) ?? 0;
        if (splittedCartonId != cartonId) {
          handleInvalidCode(context, controller, code);
          return;
        }
      } else if (prodId != productId) {
        handleInvalidCode(context, controller, code);
        return;
      }

      if (fromStockVerification) {
        final provider =
            Provider.of<StockVerificationProvider>(context, listen: false);

        final prodId = int.tryParse(code.split('-').first) ?? 0;
        if (prodId != productId || provider.scannedUnits.contains(code)) {
          handleInvalidCode(context, controller, "Already Scanned Product");
          return;
        }

        final success = provider.onScanProduct(
          context,
          productId,
          code,
          fromStockVerification: fromStockVerification,
        );
        if (!success && context.mounted) {
          handleInvalidCode(context, controller, code);
        } else {
          controller.start();
          hasScanned = false;
        }
      } else if (fromTransfer) {
        showLoading(context);
        final result =
            await Provider.of<PackerTransferProvider>(context, listen: false)
                .scanProduct(context, productId, code);
        if ((result) && context.mounted) {
          removeLoading(context);
          Navigator.pop(context, true);
        } else if (context.mounted) {
          removeLoading(context);
          controller.start();
          hasScanned = false;
        }
      }
    } catch (e) {
      handleInvalidCode(context, controller, code);
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
    // Any cleanup specific to cart item scanning
  }
}
