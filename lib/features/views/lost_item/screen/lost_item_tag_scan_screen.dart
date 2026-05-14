import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class LostItemTagScanScreen extends BaseScanScreen {
  final int productId;
  final List<String> scannedTags = [];
  final ValueNotifier<int> tagCount = ValueNotifier(0);

  LostItemTagScanScreen({
    super.key,
    required this.productId,
  }) : super(
          scanTitle: 'Scan Available Tags',
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return ValueListenableBuilder<int>(
      valueListenable: tagCount,
      builder: (_, count, __) => FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: count > 0 ? () => Navigator.pop(context, scannedTags) : null,
        label: Text(
          'Submit ($count)',
          style: const TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    HapticFeedback.heavyImpact();
    controller.stop();

    try {
      if (!code.contains('-')) {
        throw Exception('Scan a valid product tag QR code.');
      }

      final prodId = int.tryParse(code.split('-').first) ?? 0;
      if (prodId != productId) {
        throw Exception('Tag does not belong to this product.');
      }

      if (scannedTags.contains(code)) {
        showToast('Tag already scanned');
        controller.start();
        return;
      }

      scannedTags.add(code);
      tagCount.value = scannedTags.length;
      showToast('Tag scanned (${scannedTags.length})');
      controller.start();
    } catch (e) {
      await ShowAlertDialog(
        body:
            Text('Invalid QR: ${e.toString().replaceFirst('Exception: ', '')}'),
        okFunc: () {
          Navigator.pop(context);
          controller.start();
        },
      ).showAlertDialog(context);
    }
  }

  @override
  void onDispose(MobileScannerController controller) {
    controller.dispose();
  }

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, 'Scan all available tags for the lost item');
  }
}
