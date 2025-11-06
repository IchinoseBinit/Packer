import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/extensions/num_extension.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/widgets/amount_display.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class UnsettledOrdersScreen extends StatefulWidget {
  const UnsettledOrdersScreen({super.key});

  @override
  State<UnsettledOrdersScreen> createState() => _UnsettledOrdersScreenState();
}

class _UnsettledOrdersScreenState extends State<UnsettledOrdersScreen> {
  late final Future future;

  @override
  void initState() {
    future = Provider.of<OrderProvider>(context, listen: false)
        .fetchUnsettledOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Unsettled Orders'),
        ),
        bottomNavigationBar: Consumer<OrderProvider>(builder: (_, val, __) {
          if (val.unsettledOrders == null ||
              (val.unsettledOrders?.data ?? []).isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.only(
              left: AppConstants.bottomNavBarButtonPadding.left,
              right: AppConstants.bottomNavBarButtonPadding.right,
              bottom: AppConstants.bottomNavBarButtonPadding.bottom,
            ),
            child: GeneralElevatedButton(
              marginH: 0,
              title: "Settle",
              onPressed: () async {
                showLoading(context);
                val.createSettlementRequest().then((v) {
                  removeLoading(context);
                  if (v is bool) {
                    showToast("Settlement Created Successfully!!!");
                    navigatePop(context);
                  } else {
                    showToast(v.toString());
                  }
                });
              },
            ),
          );
        }),
        body: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (snapshot.hasData) {
                return Center(
                  child: Text(
                    snapshot.data.toString(),
                  ),
                );
              }
              return Consumer<OrderProvider>(builder: (_, val, __) {
                if (val.unsettledOrders == null) {
                  return const Center(
                      child: Text("Your orders has been settled"));
                }

                final unsettledOrders = val.unsettledOrders!;
                return Padding(
                  padding: AppConstants.padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Summary',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Total Orders: ${unsettledOrders.summary.orderCount}'),
                              AmountDisplay(
                                title: 'Total Amount:',
                                value: unsettledOrders.summary.totalAmount,
                              ),
                              // Text(
                              //   'Total Commission: Rs. ${unsettledOrders.summary.totalCommission.toIntStringConversion()}',
                              //   style: Theme.of(context).textTheme.bodyLarge,
                              // ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24.h,
                      ),
                      if (unsettledOrders.data.isEmpty)
                        const Center(
                            child: Text("Your Orders are already settled"))
                      else ...[
                        const Text("Your Orders"),
                        Expanded(
                          child: ListView.separated(
                            itemCount: unsettledOrders.data.length,
                            separatorBuilder: (context, index) => SizedBox(
                              height: 16.h,
                            ),
                            itemBuilder: (context, index) {
                              final order = unsettledOrders.data[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.fillColor,
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: ListTile(
                                  title: Text(
                                    'Order ID: ${order.id}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  subtitle: Text(
                                    DateFormatter().formatTimestamp(
                                        order.completedDateTime),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  trailing: Text(
                                    "Rs. ${order.total.toIntStringConversion()}",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  // TODO: For commissions add here
                                  // Column(
                                  //   crossAxisAlignment: CrossAxisAlignment.end,
                                  //   children: [
                                  //     Text(
                                  //       "Rs. ${order.commission.toIntStringConversion()}",
                                  //       style: Theme.of(context)
                                  //           .textTheme
                                  //           .bodyLarge,
                                  //     ),
                                  //     Text(
                                  //       "Rs. ${order.total.toIntStringConversion()}",
                                  //       style: Theme.of(context)
                                  //           .textTheme
                                  //           .bodyMedium,
                                  //     ),
                                  //   ],
                                  // ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              });
            }));
  }
}
