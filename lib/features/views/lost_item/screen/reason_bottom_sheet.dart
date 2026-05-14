import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/lost_item/api/lost_item_api.dart';
import 'package:packer/features/views/lost_item/enum/lost_reason_enum.dart';
import 'package:packer/features/views/lost_item/screen/lost_item_tag_scan_screen.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class ReasonBottomSheet {
  static show(
    BuildContext context, {
    int? prodId,
    int? scannedCount,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (context) =>
          ReasonBottomSheetWidget(prodId: prodId, scannedCount: scannedCount),
    );
  }
}

class ReasonBottomSheetWidget extends StatefulWidget {
  const ReasonBottomSheetWidget({
    super.key,
    this.prodId,
    this.scannedCount,
  });

  final int? prodId;
  final int? scannedCount;

  @override
  State<ReasonBottomSheetWidget> createState() =>
      _ReasonBottomSheetWidgetState();
}

class _ReasonBottomSheetWidgetState extends State<ReasonBottomSheetWidget> {
  LostReasonEnum? selectedReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Reason for Missing Item",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // if scanned count is greater than 0 show partial missing reason
          if (widget.scannedCount != null && widget.scannedCount! > 0) ...[
            Text(
              "Scanned Count: ${widget.scannedCount}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
          ],

          ...LostReasonEnum.values
              .where((reason) =>
                  (widget.scannedCount != null && widget.scannedCount! > 0)
                      ? reason == LostReasonEnum.partialMissing
                      : true)
              .map(
                (reason) => InkWell(
                  onTap: () {
                    setState(() {
                      selectedReason = reason;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedReason == reason
                          ? AppColors.primaryColor.withValues(alpha: 0.06)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reason.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                reason.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selectedReason == reason
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: GeneralElevatedButton(
                  height: 32.h,
                  onPressed: () async {
                    if (selectedReason == null) {
                      showToast("Please select a reason");
                      return;
                    }

                    if (widget.prodId != null &&
                        selectedReason == LostReasonEnum.notAvailable) {
                      _submitLostItem(
                        context: context,
                        prodId: widget.prodId!,
                      );
                      Navigator.pop(context);
                      return;
                    }

                    if (widget.prodId != null &&
                        selectedReason == LostReasonEnum.partialMissing) {
                      final tags =
                          await Navigator.of(context).push<List<String>>(
                        MaterialPageRoute(
                          builder: (_) => LostItemTagScanScreen(
                              productId: widget.prodId ?? 0),
                        ),
                      );

                      if (tags == null || tags.isEmpty) {
                        showToast('No tags scanned. Cancelled.');
                        return;
                      }

                      _submitLostItem(
                        context: context,
                        prodId: widget.prodId ?? 0,
                        scannedTags: tags,
                      );
                      Navigator.pop(context);
                      return;
                    }

                    Navigator.pop(context, selectedReason);
                  },
                  title: "Submit",
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _submitLostItem({
    required BuildContext context,
    required int prodId,
    List<String> scannedTags = const [],
  }) async {
    try {
      final item = <String, dynamic>{
        'product_id': prodId,
        'reason': scannedTags.isNotEmpty
            ? LostReasonEnum.partialMissing.value
            : LostReasonEnum.notAvailable.value,
        'tags': scannedTags.toList(),
      };

      await LostItemApi.postLostItems(items: item);

      if (context.mounted) {
        showToast('Lost item reported successfully');
      }
      Navigator.pop(context);
    } catch (e) {
      showToast(e.toString());
    }
  }
}
