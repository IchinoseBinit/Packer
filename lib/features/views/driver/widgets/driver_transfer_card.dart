import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/driver/model/driver_transfer_model.dart';
import 'package:packer/utils/google_map_utils.dart';

class DriverTransferCard extends StatelessWidget {
  final DriverTransferModel transferItem;
  final bool needAction;
  final VoidCallback callback;
  final bool needDetails;
  final bool needGoToStore;
  final bool fromTransit;

  const DriverTransferCard({
    super.key,
    required this.transferItem,
    required this.callback,
    this.needAction = true,
    this.needDetails = true,
    this.needGoToStore = true,
    this.fromTransit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: AppColors.primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: const Icon(Icons.shopping_cart, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: "Store:",
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text:
                                  " ${transferItem.destinationStoreName}",
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          ],
                        ),
                      ),
                      Text(
                        'Transfer ID: ${transferItem.inventoryTransferId}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      Text(
                        'Basket Count: ${transferItem.basketIdentifiers.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (needAction) ...[
            SizedBox(height: 12.h),
            const Divider(),

            SizedBox(height: 12.h),
            Row(
              spacing: 12.w,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (needDetails) 
                GestureDetector(
                  onTap: ()  {
                   callback();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
                if (needGoToStore) 
                GestureDetector(
                  onTap: ()  {
                    MapUtils.openMap(transferItem.destinationStoreLatitude, transferItem.destinationStoreLongitude);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Text(
                      'Go to Store',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            ],
            if (fromTransit) ...[
            SizedBox(height: 12.h),
            const Divider(),

            SizedBox(height: 12.h),
            Row(
              spacing: 12.w,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (needDetails) 
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: ()  {
                     callback();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Text(
                        'Details',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primaryColor,
                            ),
                      ),
                    ),
                  ),
                ),
                if (needGoToStore) 
                Expanded(
                  flex: 5,
                  child: GestureDetector(
                    onTap: ()  {
                      MapUtils.openMap(transferItem.destinationStoreLatitude, transferItem.destinationStoreLongitude);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Text(
                        'Go to Store',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ]
          ],
        ),
      ),
    );
  }
}
