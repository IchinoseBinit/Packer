// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/grn_expiry/providers/grn_expiry_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:provider/provider.dart';

/// Scan a carton (GRN) QR: claim it, then upload MRP / expiry photos.
class GrnExpiryScanScreen extends BaseScanScreen {
  const GrnExpiryScanScreen({super.key}) : super(scanTitle: 'Carton Intake');

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan GRN Code");
  }

  @override
  Widget? buildFloatingButton(
          BuildContext context, MobileScannerController controller) =>
      null;

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    controller.stop();
    HapticFeedback.heavyImpact();
    if (code.trim().isEmpty) {
      showToast('Invalid QR');
      controller.start();
      return;
    }

    showLoading(context, label: 'Claiming carton...');
    try {
      await context.read<GrnExpiryProvider>().claimQr(code.trim());
      removeLoading(context);
    } catch (e) {
      removeLoading(context);
      showToast(e.toString());
      controller.start();
      return;
    }

    final submitted = await navigate(context,
        route: NavigationConstants.grnExpiryPhotosRoute);
    if (!context.mounted) return;
    if (submitted == true) {
      navigatePop(context);
    } else {
      controller.start();
    }
  }

  @override
  void onDispose(MobileScannerController controller) {}
}
