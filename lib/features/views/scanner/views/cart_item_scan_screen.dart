import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/lost_item/enum/lost_reason_enum.dart';
import 'package:packer/features/views/lost_item/screen/image_upload_bottom_sheet.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class CartItemScanScreen extends BaseScanScreen {
  final int productId;
  bool hasScanned = false;

  CartItemScanScreen({
    super.key,
    required this.productId,
  }) : super(
          scanTitle: 'Product Scanner',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    final message = Provider.of<OrderProvider>(context, listen: false)
        .scanProductMessage(productId);
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    final show = context.read<OrderProvider>().hasNearExpiryTag(productId);
    if (show) {
      return FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () async {
          context.read<OrderProvider>().showProductTags(context, productId);
        },
        child: const Icon(
          Icons.info,
          color: Colors.white,
        ),
      );
    }

    //  show button to report for missing items
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          //
          final scannedCount = orderProvider.countScannedItem(productId);
          //

          LostReasonEnum lost = scannedCount > 0
              ? LostReasonEnum.partialMissing
              : LostReasonEnum.notAvailable;

          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              controller.stop();

              // ask for confirmation to report lost item with reason
              bool? confirmation = await ShowAlertDialog(
                title: 'Report Lost Item',
                body: Text(
                    '${scannedCount > 0 ? 'Scanned - $scannedCount' : 'Product not available'} \nAre you sure you want to report as lost?'),
                okFunc: () => Navigator.pop(context, true),
                cancelFunc: () => Navigator.pop(context, false),
                okTitle: "Yes",
                cancelTitle: "No",
                needCancel: true,
                canDismiss: false,
              ).showAlertDialog(context);

              if (confirmation == null || !confirmation) {
                controller.start();
                return;
              }

              await ImageUploadBottomSheet.show(
                context: context,
                lost: lost,
                prodId: productId,
                orderId: context.read<OrderProvider>().orderDetails!.data.id,
                scannedCount: scannedCount,
                scannedTags: orderProvider.scannedDataList
                    .where(
                      (item) => item.startsWith(productId.toString()),
                    )
                    .toList(),
              );
              controller.start();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.report_problem,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  lost.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
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
      // showLoading(context);

      // split code to get product id
      final prodId = int.tryParse(code.split('-').first) ?? 0;
      if (prodId != productId) {
        handleInvalidCode(context, controller, code);
        return;
      }

      final result = Provider.of<OrderProvider>(context, listen: false)
          .scanProduct(context, productId, code);

      if (result.success && context.mounted) {
        hasScanned = false;
        if (result.message != null) {
          showToast(result.message ?? '');
        }
        Navigator.pop(context, true);
      } else if (context.mounted) {
        if (result.message != null) {
          handleInvalidCode(context, controller, code, result.message);
        } else {
          hasScanned = false;
          controller.start();
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
