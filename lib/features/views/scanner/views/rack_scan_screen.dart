import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class RackScanScreen extends BaseScanScreen {
  final String? rackCode;
  final int productId;
  final bool forCarton;
  final bool forDamage;

  RackScanScreen({
    super.key,
    this.rackCode,
    required this.productId,
    this.forCarton = false,
    this.forDamage = false,
  }) : super(
          scanTitle: 'Rack Scanner',
          showFlash: true,
          showBackButton: true,
        );

  bool _isProcessing = false;

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
        context, rackCode == null ? "Assign a rack" : "Scan Rack $rackCode");
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    debugger();
    if (code.isEmpty) return;
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await controller.stop();
      HapticFeedback.heavyImpact();

      if (!code.contains("rack")) {
        handleInvalidCode(context, controller, code);
        return;
      }

      if (rackCode != null) {
        if (code.contains(rackCode!)) {
          await controller.dispose();
          if (context.mounted) {
            navigatePop(context, true);
          }
          showToast("Rack scanned successfully");
        } else {
          if (context.mounted) handleInvalidCode(context, controller, code);
        }
      } else if (forCarton) {
        final result = await Provider.of<StockProvider>(context, listen: false)
            .updateRack(context, code, productId, true);

        if (result && context.mounted) {
          navigatePop(context, true);
          showToast("Rack Assigned successfully");
        } else {
          if (context.mounted) await controller.start();
        }
      } else if (forDamage) {
        try {
          Provider.of<PackerTransferProvider>(context, listen: false)
              .postDamageProductTags(context, productId, code);

          await controller.stop();

          if (context.mounted) {
            showToast("Rack Scanned Successfully");

            navigatePop(context, true);
           
          } else {
            if (context.mounted) {
              showToast("Rack update failed");
            }
          }
        } catch (e) {
          if (context.mounted) {
            showToast("Error: $e");
          }
        }
      } else if (context.mounted) {
        showLoading(context);

        // final isMainStore =
        //     Provider.of<StockVerificationProvider>(context, listen: false)
        //         .storeList
        //         .any((store) => store.isMainStore);

        final result =
            await Provider.of<PackerTransferProvider>(context, listen: false)
                .updateRack(context, code, productId);

        if (context.mounted) removeLoading(context);

        // if (isMainStore) {
        //   navigateReplacement(
        //     context,
        //     route: NavigationConstants.cartonListScreenRoute,
        //     extra: productId,
        //   );
        // }

        if (result && context.mounted) {
          navigateReplacement(
            context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              "forTransfer": true,
              "productId": productId,
            },
          );
        } else {
          if (context.mounted) await controller.start();
        }
      }
    } catch (e) {
      if (context.mounted) {
        handleInvalidCode(context, controller, code);
      }
    } finally {
      _isProcessing = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code) {
    ShowAlertDialog(
      disableBackground: true,
      canDismiss: true,
      body: Text("Invalid QR ${detectQrMessage(code)}"),
      okFunc: () async {
        Navigator.pop(context);
        await controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Optional cleanup
  }
}
