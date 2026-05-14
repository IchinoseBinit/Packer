import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/lost_item/api/lost_item_api.dart';
import 'package:packer/features/views/lost_item/enum/lost_reason_enum.dart';
import 'package:packer/features/views/lost_item/screen/lost_item_tag_scan_screen.dart';
import 'package:packer/features/views/lost_item/screen/reason_bottom_sheet.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class LostItemScreen extends BaseScanScreen {
  const LostItemScreen({super.key}) : super(scanTitle: "Scan Missing Product");

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    HapticFeedback.heavyImpact();
    controller.stop();

    try {
      if (!code.contains('-')) {
        throw Exception('Scan a valid QR code of the missing product.');
      }

      final prodId = int.tryParse(code.split('-').first);
      if (prodId == null) {
        throw Exception('Invalid product QR code.');
      }

      final reason = await ReasonBottomSheet.show(context) as LostReasonEnum?;

      if (reason == null || !context.mounted) {
        controller.start();
        return;
      }

      if (reason == LostReasonEnum.notAvailable) {
        await _submitLostItem(
          context: context,
          prodId: prodId,
          scannedTags: null,
        );
      } else {
        final navigator = Navigator.of(context);
        final tags = await navigator.push<List<String>>(
          MaterialPageRoute(
            builder: (_) => LostItemTagScanScreen(productId: prodId),
          ),
        );

        if (!context.mounted) return;

        if (tags == null || tags.isEmpty) {
          showToast('No tags scanned. Cancelled.');
          controller.start();
          return;
        }

        await _submitLostItem(
          context: context,
          prodId: prodId,
          scannedTags: tags,
        );

        navigator.pop();
      }
    } catch (e) {
      await _handleInvalidCode(context, controller, code, e.toString());
      return;
    }

    controller.start();
  }

  Future<void> _submitLostItem({
    required BuildContext context,
    required int prodId,
    List<String>? scannedTags,
  }) async {
    try {
      final item = <String, dynamic>{
        'product_id': prodId,
        'reason': (scannedTags != null && scannedTags.isNotEmpty)
            ? LostReasonEnum.partialMissing.value
            : LostReasonEnum.notAvailable.value,
        if (scannedTags != null && scannedTags.isNotEmpty) 'tags': scannedTags,
      };

      await LostItemApi.postLostItems(items: item);

      if (context.mounted) {
        showToast('Lost item reported successfully');
      }
    } catch (e) {
      showToast(e.toString());
    }
  }

  Future<void> _handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) async {
    await ShowAlertDialog(
      body: Text(
          'Invalid QR: ${message?.replaceFirst('Exception: ', '') ?? detectQrMessage(code)}'),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    controller.dispose();
  }

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, 'Scan the QR code of the missing product');
  }
}
