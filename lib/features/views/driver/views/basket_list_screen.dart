import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/driver/controller/driver_controller.dart';
import 'package:packer/features/views/driver/model/driver_transfer_model.dart';
import 'package:packer/features/views/driver/widgets/driver_transfer_card.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class BasketListScreen extends StatefulWidget {
  const BasketListScreen(
      {super.key, required this.transferItem, this.fromInTransit = false});

  final DriverTransferModel transferItem;
  final bool fromInTransit;

  @override
  State<BasketListScreen> createState() => _BasketListScreenState();
}

class _BasketListScreenState extends State<BasketListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Transfer Details"),
        ),
        body: Padding(
          padding: AppConstants.padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriverTransferCard(
                transferItem: widget.transferItem,
                needAction: false,
                callback: () {},
              ),
              // 12.h
              SizedBox(height: 12.h),
              Text("Basket List"),
              // 12.h
              SizedBox(height: 12.h),
              Consumer<DriverController>(
                builder: (context, driverController, child) {
                  return Expanded(
                    child: ListView.builder(
                      itemCount: widget.transferItem.basketIdentifiers.length,
                      itemBuilder: (context, index) {
                        final basketIdentifier =
                            widget.transferItem.basketIdentifiers[index];
                        return BasketCard(
                          basketIdentifier: basketIdentifier,
                          index: index + 1,
                          showStatus: !widget.fromInTransit,
                          // scanned: driverController
                          //     .isBasketScanned(basketIdentifier),
                        );
                      },
                    ),
                  );
                },
              )
            ],
          ),
        ),
        bottomNavigationBar: widget.fromInTransit
            ? null
            : Consumer<DriverController>(
                builder: (context, driverController, child) {
                  return Padding(
                    padding: AppConstants.padding,
                    child: GeneralElevatedButton(
                        title: driverController.isAllBasketScanned()
                            ? "Complete"
                            : "Scan Basket",
                        onPressed: () {
                          driverController.isAllBasketScanned()
                              ? Provider.of<DriverController>(context,
                                      listen: false)
                                  .completeTransfer(context)
                              : navigate(
                                  context,
                                  route: NavigationConstants
                                      .driverBasketScannerRoute,
                                );
                        }),
                  );
                },
              ));
  }
}

class BasketCard extends StatelessWidget {
  final String basketIdentifier;
  final int index;
  final bool scanned;
  final bool showStatus;

  const BasketCard({
    super.key,
    required this.basketIdentifier,
    required this.index,
    this.scanned = false,
    this.showStatus = true,
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.shopping_basket, color: Colors.white),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index.toString()}. ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Flexible(
                    child: Text(
                      basketIdentifier,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
            showStatus
                ? Text(
                    scanned ? 'Scanned' : 'Not Scanned',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scanned
                              ? AppColors.green700
                              : AppColors.primaryColor,
                        ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
