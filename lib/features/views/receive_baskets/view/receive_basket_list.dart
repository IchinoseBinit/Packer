import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/driver/views/basket_list_screen.dart';
import 'package:packer/features/views/receive_baskets/controller/receive_basket_controller.dart';
import 'package:packer/features/views/receive_baskets/view/widget/receive_transfer_card.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class ReceiveBasketList extends StatefulWidget {
  const ReceiveBasketList({super.key});

  @override
  State<ReceiveBasketList> createState() => _ReceiveBasketListState();
}

class _ReceiveBasketListState extends State<ReceiveBasketList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Transfer Details"),
        ),
        body: Consumer<ReceiveBasketController>(
          builder: (context, controller, child) {
            final transferItem = controller.selectedTransfer;
            if (transferItem == null) {
              return const Center(
                child: Text("No Transfer found"),
              );
            }
            return Padding(
              padding: AppConstants.padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReceiveTransferCard(
                    transferItem: transferItem,
                    needAction: false,
                    callback: () {},
                  ),
                  // 12.h
                  SizedBox(height: 12.h),
                  Text("Basket List"),
                  // 12.h
                  SizedBox(height: 12.h),
                  Consumer<ReceiveBasketController>(
                    builder: (context, controller, child) {
                      return Expanded(
                        child: ListView.builder(
                          itemCount: transferItem.basketIdentifiers.length,
                          itemBuilder: (context, index) {
                            final basketIdentifier =
                                transferItem.basketIdentifiers[index];
                            return BasketCard(
                              basketIdentifier: basketIdentifier,
                              index: index + 1,
                              scanned:
                                  controller.isBasketScanned(basketIdentifier),
                            );
                          },
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Consumer<ReceiveBasketController>(
          builder: (context, controller, child) {
            return Padding(
              padding: AppConstants.padding,
              child: GeneralElevatedButton(
                  title: controller.isAllBasketScanned()
                      ? "Complete"
                      : "Scan Basket",
                  onPressed: () {
                    controller.isAllBasketScanned()
                        ? Provider.of<ReceiveBasketController>(context,
                                listen: false)
                            .completeTransfer(context)
                        : navigate(
                            context,
                            route: NavigationConstants.receiveBasketScannerRoute,
                          );
                  }),
            );
          },
        ));
  }
}
