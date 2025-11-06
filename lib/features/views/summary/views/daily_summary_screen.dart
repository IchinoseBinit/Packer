import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/extensions/num_extension.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/summary/models/daily_summary.dart';
import 'package:packer/features/views/widgets/amount_display.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key, required this.startDate});

  final String startDate;

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  late Future<void> future;

  @override
  void initState() {
    future = Provider.of<OrderProvider>(context, listen: false)
        .fetchDailySummary(startDate: widget.startDate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Summary Screen"),
      ),
      body: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final dailySummary =
              Provider.of<OrderProvider>(context, listen: false).dailySummary;
          if (dailySummary == null) {
            return const Text("Summary not available");
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: 1.sw,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AmountDisplay(
                            title: "Cash Payment",
                            value: dailySummary.cashPayment),
                        Text("Total Orders: ${dailySummary.count}"),
                        Text(
                            "Total Distance: ${dailySummary.distance.toIntStringConversion()} KMs"),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 16.h,
                  ),
                  Text(
                    "Orders:",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  ListView.builder(
                    itemBuilder: (context, index) {
                      final order = dailySummary.orders[index];
                      return buildSummaryItem(context, order);
                    },
                    itemCount: dailySummary.orders.length,
                    shrinkWrap: true,
                    primary: false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSummaryItem(BuildContext context, DailyOrderSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order ID: ${summary.id}",
              ),
              SizedBox(
                height: 2.h,
              ),
              Text(
                "Amount: Rs. ${summary.total.toIntStringConversion()}",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14.sp,
                    ),
              ),
              if (summary.settlementDate != null)
                Text(
                  "Settled at: ${DateFormatter().formatTimestamp(summary.settlementDate.toString())}",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 12.sp,
                        color: Colors.green,
                      ),
                ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => navigate(
              context,
              route: NavigationConstants.orderDetailsRoute,
              extra: summary.id,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: AppColors.primaryColor,
              ),
              height: 32.h,
              width: 32.h,
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
