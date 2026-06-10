import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/lost_item/api/lost_item_api.dart';
import 'package:packer/features/views/lost_item/enum/lost_reason_enum.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'dart:io';
import 'package:packer/utils/app_image_picker.dart';
import 'package:provider/provider.dart';

class ImageUploadBottomSheet {
  static show({
    required BuildContext context,
    required LostReasonEnum lost,
    required int prodId,
    int? orderId,
    required int scannedCount,
    // need tags
    List<String>? scannedTags,
  }) async {
    return await showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: false,
      enableDrag: false,
      builder: (context) => ImageUploadBottomSheetWidget(
        lostReason: lost,
        prodId: prodId,
        orderId: orderId,
        scannedCount: scannedCount,
        scannedTags: scannedTags,
      ),
    );
  }
}

class ImageUploadBottomSheetWidget extends StatefulWidget {
  const ImageUploadBottomSheetWidget({
    super.key,
    required this.lostReason,
    required this.prodId,
    required this.orderId,
    required this.scannedCount,
    this.scannedTags,
  });

  final LostReasonEnum lostReason;
  final int prodId;
  final int? orderId;
  final int scannedCount;
  final List<String>? scannedTags;

  @override
  State<ImageUploadBottomSheetWidget> createState() =>
      _ImageUploadBottomSheetWidgetState();
}

class _ImageUploadBottomSheetWidgetState
    extends State<ImageUploadBottomSheetWidget> {
  XFile? _pickedImagePath;

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
            "Lost Confirmation - ${widget.lostReason.name}",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload image of rack where items were stored to help us investigate the issue.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          // Image upload / preview
          InkWell(
            onTap: () async {
              // Use the app image picker to pick an image. Expected to return a File or path.
              final res = await AppImagePicker.pickImage(context);
              if (res == null) return;
              //
              setState(() {
                _pickedImagePath = res;
              });
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _pickedImagePath == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 28, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Upload image',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_pickedImagePath!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
          ),

          Text(
            widget.scannedCount <= 0
                ? "Product is not found in the rack. Please upload image as evidence to report the issue."
                : "You have scanned ${widget.scannedCount} item(s) for this product. If you are reporting as not available then you can submit with current scanned items or if you want to report as partially missing then you need to scan the remaining tags.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),

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
                    if (_pickedImagePath == null) {
                      showToast('Please upload an image to proceed');
                      return;
                    }

                    List<String> tags = widget.scannedTags ?? [];

                    if (widget.scannedTags != null &&
                        widget.scannedTags!.isEmpty) {
                      tags = context
                          .read<OrderProvider>()
                          .scannedDataList
                          .where(
                            (item) => item.startsWith(widget.prodId.toString()),
                          )
                          .toList();
                    }

                    if (widget.lostReason == LostReasonEnum.partialMissing &&
                        widget.scannedTags != null &&
                        tags.isEmpty) {
                      showToast(
                          'Please scan the remaining tags to report as partially missing');
                      return;
                    }

                    _submitLostItem(
                      context: context,
                      prodId: widget.prodId,
                      scannedTags: tags,
                      file: _pickedImagePath!,
                      orderId: widget.orderId,
                    );
                    Navigator.pop(context);
                    return;
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
    required XFile file,
    List<String> scannedTags = const [],
    int? orderId,
  }) async {
    try {
      showLoading(context, label: 'Submitting lost item report...');

      await LostItemApi.postLostItems(
        prodId: prodId,
        file: file,
        scannedTags: scannedTags,
        orderId: orderId,
      );

      // if it get success then clear all the scanned data in order provider for that product id
      if (orderId != null) {
        await context.read<OrderProvider>().clearScannedDataOrder(orderId);
      }

      if (context.mounted) {
        showToast('Lost item reported successfully');
      }
      removeLoading(context);
      navigateReplacement(context, route: NavigationConstants.dashboardRoute);
    } catch (e) {
      showToast(e.toString());
      removeLoading(context);
    }
  }
}
