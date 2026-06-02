import 'package:flutter/material.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/damage_products/controller/damage_product_controller.dart';
import 'package:packer/features/views/lost_item/enum/lost_reason_enum.dart';
import 'package:packer/features/views/lost_item/screen/image_upload_bottom_sheet.dart';
import 'package:packer/features/views/lost_item/screen/lost_item_tag_scan_screen.dart';
import 'package:packer/features/views/lost_item/screen/reason_bottom_sheet.dart';
import 'package:packer/features/views/widgets/file_upload.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class RackProductList extends StatefulWidget {
  const RackProductList({
    super.key,
    this.forLostItem = false,
  });

  final bool forLostItem;

  @override
  State<RackProductList> createState() => _RackProductListState();
}

class _RackProductListState extends State<RackProductList> {
  @override
  Widget build(BuildContext context) {
    final damageProductController =
        Provider.of<DamageProductController>(context, listen: false);

    final productList = damageProductController.rackProductList;
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: Text("Rack Product List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 8.0),
          itemBuilder: (context, index) {
            final item = productList[index];
            return InkWell(
              onTap: () async {
                if (widget.forLostItem) {
                  // Handle lost item logic
                  final LostReasonEnum? reason =
                      await ReasonBottomSheet.show(context);
                  //
                  if (reason == null) return;
                  //
                  if (reason == LostReasonEnum.notAvailable) {
                    await ImageUploadBottomSheet.show(
                      context: context,
                      lost: reason,
                      prodId: item.id,
                      scannedCount: 0,
                      scannedTags: null,
                    );
                    return;
                  } else if (reason == LostReasonEnum.partialMissing) {
                    //
                    final tags = await Navigator.push<List<String>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LostItemTagScanScreen(productId: item.id),
                      ),
                    );

                    if (!context.mounted) return;

                    if (tags == null || tags.isEmpty) {
                      showToast('No tags scanned. Cancelled.');
                      return;
                    }

                    //
                    await ImageUploadBottomSheet.show(
                      context: context,
                      lost: reason,
                      prodId: item.id,
                      scannedCount: tags.length,
                      scannedTags: tags,
                    );
                    return;
                  }
                }

                await fileUpload(context, item.id, item.quantity);
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.primaryColor),
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ID: ${item.id}"),
                      Text("Quantity: ${item.quantity}"),
                    ],
                  ),
                ),
              ),
            );
          },
          itemCount: productList.length,
          shrinkWrap: true,
          physics: AlwaysScrollableScrollPhysics(),
        ),
      ),
    );
  }
}
