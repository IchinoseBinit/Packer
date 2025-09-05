import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order_return/model/order_return_model.dart';
import 'package:packer/features/views/order_return/views/order_return_card.dart';
import 'package:packer/features/views/order_return/provider/order_return_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class OrderReturnList extends StatelessWidget {
  const OrderReturnList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: const Text('Order Return List'),
      ),
      body: FutureBuilder<List<OrderReturnModel>>(
        future: Provider.of<OrderReturnProvider>(context, listen: false)
            .fetchOrderReturns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No order returns found'),
            );
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final orderReturn = snapshot.data![index];
                return ReturnOrderCard(
                  orderId: orderReturn.orderId.toString(),
                  productCount: orderReturn.orderItems.length,
                  time: orderReturn.createdAt,
                  basketId: orderReturn.basket,
                  primaryColor: Theme.of(context).primaryColor,
                  onTap: () {
                    Provider.of<OrderReturnProvider>(context, listen: false).onScanBasketTaped(context, orderReturn);
                    // navigate(context,
                    //     route: NavigationConstants.orderReturnScreenRoute,
                    //     extra: {"orderReturn": orderReturn});
                  },
                );
              },
            ),
          );
        }
      ),
    );
  }
}