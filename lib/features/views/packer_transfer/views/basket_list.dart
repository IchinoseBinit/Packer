import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/packer_transfer/model/basket_model.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class BasketList extends StatelessWidget {
  const BasketList({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        navigatePop(context);
        Provider.of<PackerTransferProvider>(context, listen: false)
            .fetchTransferList(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Basket List"),
          centerTitle: true,
        ),
        body: Consumer<PackerTransferProvider>(
          builder: (context, provider, child) {
            if (provider.selectedTransferModelLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (provider.selectedTransferModel?.baskets == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (provider.selectedTransferModel?.baskets?.isEmpty ?? true) {
              return const Center(
                child: Text("No baskets available"),
              );
            }
            return Column(
              children: [
                Expanded( 
                  child: ListView.builder(
                    itemCount: provider.selectedTransferModel?.baskets?.length,
                    padding: EdgeInsets.all(16.w),
                    itemBuilder: (context, index) {
                      final data =
                          provider.selectedTransferModel!.baskets![index];
                      return BasketCard(
                        index: index + 1,
                        model: data,
                        primaryColor: Theme.of(context).primaryColor,
                        callback: () {
                          // Handle item tap
                          Provider.of<PackerTransferProvider>(context,
                                  listen: false)
                              .onBasketScanTapped(context, data);
                        },
                      );
                    },
                  ),
                ),
                GeneralElevatedButton(
                    title: "Scan Basket",
                    onPressed: () {
                      navigate(
                        context,
                        route: NavigationConstants.qrScanScreenRoute,
                        extra: {"forBasket": true},
                      );
                    })
              ],
            );
          },
        ),
      ),
    );
  }
}

class BasketCard extends StatelessWidget {
  final BasketModel model;
  final Color primaryColor;
  final int index;
  final VoidCallback? callback;

  const BasketCard({
    super.key,
    required this.index,
    required this.model,
    required this.primaryColor,
    this.callback,
  });

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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor,
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
                      model.identifier,
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
            if (callback != null) ...[
              SizedBox(height: 12.h),
              InkWell(
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
                    'Scan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
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
