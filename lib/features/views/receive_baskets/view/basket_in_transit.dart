import 'package:flutter/material.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/receive_baskets/controller/receive_basket_controller.dart';
import 'package:packer/features/views/receive_baskets/view/widget/receive_transfer_card.dart';
import 'package:provider/provider.dart';

class BasketInTransitScreen extends StatefulWidget {
  const BasketInTransitScreen({super.key});

  @override
  State<BasketInTransitScreen> createState() => _BasketInTransitScreenState();
}

class _BasketInTransitScreenState extends State<BasketInTransitScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final controller =
        Provider.of<ReceiveBasketController>(context, listen: false);
    controller.getReceiveBasketList(context, isFromBuild: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Transit'),
      ),
      body: Padding(
        padding: AppConstants.padding,
        child: Consumer<ReceiveBasketController>(
          builder: (_, controller, __) {
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (controller.receiveBasketList.isEmpty) {
              return const Center(
                child: Text('No Transfer found'),
              );
            }
            return Center(
              child: ListView.builder(
                itemCount: controller.receiveBasketList.length,
                itemBuilder: (context, index) {
                  return ReceiveTransferCard(
                    transferItem: controller.receiveBasketList[index],
                    callback: () {
                      controller.onDetailsTap(context,
                          controller.receiveBasketList[index]);
                      // Navigator.pushNamed(
                      //   context,
                      //   NavigationConstants.RECEIVE_BASKET_DETAILS,
                      //   arguments: controller.receiveBasketList[index],
                      // );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
