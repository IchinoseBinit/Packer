import 'package:flutter/material.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/inventory_transfer_main_store/controller/inventory_transfer_controller.dart';
import 'package:packer/features/views/packer_transfer/views/transfer_list.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class InventoryTransferList extends StatefulWidget {
  const InventoryTransferList({super.key});

  @override
  State<InventoryTransferList> createState() => _InventoryTransferListState();
}

class _InventoryTransferListState extends State<InventoryTransferList> {
  late Future _inventoryTransferRequestListFuture;
  @override
  void initState() {
    super.initState();
    _inventoryTransferRequestListFuture = getInventoryTransferList();
  }

  Future getInventoryTransferList() async {
    final controller =
        Provider.of<InventoryTransferController>(context, listen: false);
    return controller.getInventoryTransferList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: const Text("Inventory Transfer"),
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
              return Consumer<InventoryTransferController>(
                builder: (_, controller, __) {
                  if (controller.inventoryTransferList.isEmpty) {
                    return const Center(child: Text("No data found"));
                  }
                  return ListView.builder(
                    itemCount: controller.inventoryTransferList.length,
                    itemBuilder: (context, index) {
                      return TransferNotificationCard(
                        transferItem:
                            controller.inventoryTransferList[index],
                        primaryColor: AppColors.primaryColor,
                        callback: () {
                          // Handle callback
                          // controller.onRequestTap(context, controller.inventoryTransferRequestList[index]);
                          controller.onDetailsTap(context, controller.inventoryTransferList[index]);
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

