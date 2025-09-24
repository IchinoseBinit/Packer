import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_model.dart';
import 'package:packer/features/views/inventory_transfer_request/provider/inventory_transfer_request_controller.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class InventoryTransferRequest extends StatefulWidget {
  const InventoryTransferRequest({super.key});

  @override
  State<InventoryTransferRequest> createState() =>
      _InventoryTransferRequestState();
}

class _InventoryTransferRequestState extends State<InventoryTransferRequest> {
  late Future _inventoryTransferRequestListFuture;
  @override
  void initState() {
    super.initState();
    _inventoryTransferRequestListFuture = _getInventoryTransferRequestList();
  }

  Future _getInventoryTransferRequestList() async {
    final controller =
        Provider.of<InventoryTransferRequestController>(context, listen: false);
    return controller.getInventoryTransferRequestList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: const Text("Inventory Transfer Request"),
      ),
      body: Padding(
        padding: AppConstants.padding,
        child: FutureBuilder(
          future: _inventoryTransferRequestListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Consumer<InventoryTransferRequestController>(
                builder: (_, controller, __) {
                  if (controller.inventoryTransferRequestList.isEmpty) {
                    return const Center(child: Text("No data found"));
                  }
                  return ListView.builder(
                    itemCount: controller.inventoryTransferRequestList.length,
                    itemBuilder: (context, index) {
                      return TransferRequestNotificationCard(
                        transferItem:
                            controller.inventoryTransferRequestList[index],
                        primaryColor: AppColors.primaryColor,
                        callback: () {
                          // Handle callback
                          controller.onRequestTap(context, controller.inventoryTransferRequestList[index]);
                        },
                      );
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class TransferRequestNotificationCard extends StatelessWidget {
  final InventoryTransferRequestModel transferItem;
  final Color primaryColor;
  final VoidCallback? callback;
  final String? basketId;

  const TransferRequestNotificationCard({
    Key? key,
    required this.transferItem,
    required this.primaryColor,
    this.basketId,
    this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: primaryColor.withOpacity(0.5),
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
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.near_me, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transfer Request (${transferItem.status})",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${transferItem.sourceStore} → ${transferItem.destinationStore}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      Text(
                        'Requested at: ${DateFormatter().formatTimestamp(transferItem.createdAt)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      if (basketId != null)
                        Text(
                          'Basket ID: $basketId',
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
            if (callback != null) ...[
              SizedBox(height: 12.h),
              const Divider(),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    callback?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
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
              ),
            ]
          ],
        ),
      ),
    );
  }
}
