import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/inventory_transfer_main_store/controller/inventory_transfer_controller.dart';
import 'package:packer/features/views/packer_transfer/views/basket_list.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart' show Provider, Consumer;

class InventoryTransferBasketList extends StatelessWidget {
  const InventoryTransferBasketList({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        navigatePop(context);
        Provider.of<InventoryTransferController>(context, listen: false)
            .getInventoryTransferList();
      },
      child: Scaffold(
          appBar: GeneralAppBar(
            middleWidget: const Text("Basket List"),
            leadingOnPressed: () {
              navigatePop(context);
              Provider.of<InventoryTransferController>(context, listen: false)
                  .getInventoryTransferList();
            },
          ),
          body: Consumer<InventoryTransferController>(
            builder: (context, provider, child) {
              
              if (provider.selectedInventoryTransfer?.baskets == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (provider.selectedInventoryTransfer?.baskets?.isEmpty ?? true) {
                return const Center(
                  child: Text("No baskets available"),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount:
                          provider.selectedInventoryTransfer?.baskets?.length,
                      padding: EdgeInsets.all(16.w),
                      itemBuilder: (context, index) {
                        final data =
                            provider.selectedInventoryTransfer!.baskets![index];
                        return BasketCard(
                          index: index + 1,
                          model: data,
                          primaryColor: Theme.of(context).primaryColor,
                          callback: () {
                            // Handle item tap
                            Provider.of<InventoryTransferController>(context,
                                    listen: false).onBasketScanTapped(context, data);
                            //     .o(context, data);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: Consumer<InventoryTransferController>(
            builder: (context, provider, child) {
              if (provider.selectedInventoryTransfer?.baskets?.isEmpty ?? true) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                child: GeneralElevatedButton(
                    marginH: 16.w,
                    title:
                        // provider.selectedTransferModel?.baskets?.isEmpty ?? true
                        //     ? "Complete"
                        //     : 
                            "Scan Basket",
                    onPressed: () {
                      // if (provider.selectedTransferModel?.baskets?.isEmpty ??
                      //     true) {
                      //   Provider.of<PackerTransferProvider>(context,
                      //           listen: false)
                      //       .completeTransfer(context);
                      // } else 
                      // {
                        Provider.of<InventoryTransferController>(context,
                                listen: false)
                            .onBasketScanTapped(context, null);
                      // }
                    }),
              );
            },
          )),
    );
  }
}