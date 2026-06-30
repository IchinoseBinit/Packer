import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/fruits_vegs/widgets/rate_ripeness_widget.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class ScanTagScreen extends BaseScanScreen {
  final ProductModel productModel;

  const ScanTagScreen({
    super.key,
    required this.productModel,
  }) : super(
          scanTitle: 'Scan Tag',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<FruitsVegsProvider>(context, listen: false).clearScannedTags();

    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Tag- ${productModel.productName}");
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return Consumer<FruitsVegsProvider>(
      builder: (context, provider, _) {
        final scanned = provider.scannedTags.length;
        final total = productModel.units?.length ?? 0;
        final isAllScanned = scanned > 0 && scanned == total;

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isAllScanned
                        ? "All $total tags scanned"
                        : "Scanned $scanned of $total",
                    style: TextStyle(color: Colors.white, fontSize: 13.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'View tags',
                    onPressed: () => _showTagsSheet(context, controller),
                    icon: Icon(Icons.info_outline,
                        color: Colors.white, size: 20.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              margin: EdgeInsets.only(left: 16.w),
              padding: EdgeInsets.only(left: 16.w),
              child: GeneralElevatedButton(
                marginH: 6,
                bgColor:
                    isAllScanned ? AppColors.primaryColor : Colors.transparent,
                borderColor:
                    isAllScanned ? AppColors.primaryColor : Colors.transparent,
                onPressed: () {
                  if (isAllScanned) {
                    Navigator.pop(context);
                  } else {
                    showToast(
                      "Please scan all tags before marking as completed.",
                      color: Colors.red,
                    );
                  }
                },
                title: isAllScanned ? "Mark as Completed" : "Scan All Tags",
                textStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isAllScanned ? Colors.white : Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      final unit =
          productModel.units?.firstWhereOrNull((unit) => unit.tag == code);

      if (unit == null) {
        throw Exception("Scanned tag does not match any unit.");
      }

      if (context.read<FruitsVegsProvider>().scannedTags.contains(code)) {
        throw Exception("Tag already scanned.");
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        // isDismissible: false,
        builder: (context) => Padding(
          padding: EdgeInsets.only(top: 32.h),
          child: RateRipenessWidget(
            productModel: productModel,
            unit: unit,
          ),
        ),
      );

      controller.start();
    } catch (e) {
      handleInvalidCode(context, controller, code, e.toString());
      return;
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
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Any cleanup specific to cart item scanning
  }

  /// Bottom sheet showing every expected tag with a tick when scanned.
  Future<void> _showTagsSheet(
      BuildContext context, MobileScannerController controller) async {
    await controller.stop();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Consumer<FruitsVegsProvider>(
        builder: (context, provider, __) {
          final tags =
              productModel.units?.map((unit) => unit.tag ?? "").toList() ?? [];
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 0.8.sh),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags  (${provider.scannedTags.length}/${tags.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 12.h),
                    Flexible(
                      child: tags.isEmpty
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: const Center(child: Text('No tags')),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: tags.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 6.h),
                              itemBuilder: (context, index) {
                                final tag = tags[index];
                                final scanned =
                                    provider.scannedTags.contains(tag);
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: scanned
                                        ? Colors.green.withValues(alpha: 0.10)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        scanned
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        size: 18.r,
                                        color: scanned
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            decoration: scanned
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    await controller.start();
  }
}
