import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/extensions/num_extension.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/summary/models/weekly_summary.dart';
import 'package:packer/features/views/widgets/amount_display.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late DateTime startDate;
  late DateTime endDate;

  late Future future;

  @override
  void initState() {
    super.initState();
    endDate = DateTime.now();
    startDate = endDate.subtract(const Duration(days: 7));

    future =
        Provider.of<OrderProvider>(context, listen: false).fetchOrderSummary();
  }

  String getFormattedDate() {
    return "${DateFormat("yyyy-MMM-dd").format(startDate)} to ${DateFormat("yyyy-MMM-dd").format(endDate)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary Screen"),
      ),
      body: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final orderSummary =
              Provider.of<OrderProvider>(context, listen: false).weeklySummary;
          if (orderSummary == null) {
            return const Text("Summary not available");
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: englishDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(.4),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      width: 1.sw,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(getFormattedDate()),
                          SizedBox(
                            width: 5.w,
                          ),
                          const Icon(
                            Icons.calendar_month,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
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
                            value: orderSummary.cashPayment),
                        Text("Total Orders: ${orderSummary.count}"),
                        Text(
                            "Total Distance: ${orderSummary.distance.toIntStringConversion()} KMs"),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ListView.builder(
                    itemBuilder: (context, index) {
                      final order = orderSummary.orders[index];
                      return buildSummaryItem(context, order);
                    },
                    itemCount: orderSummary.orders.length,
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

  void englishDatePicker() async {
    try {
      final selectedEngDateTime = await showDateRangePicker(
        context: context,
        lastDate: DateTime.now(),
        firstDate: DateTime(2024, 9),
        currentDate: startDate,
      );
      if (selectedEngDateTime != null) {
        startDate = selectedEngDateTime.start;
        endDate = selectedEngDateTime.end;
        setState(() {
          future = Provider.of<OrderProvider>(context, listen: false)
              .fetchOrderSummary(
            startDate: DateFormat("yyyy-MM-dd").format(startDate),
            endDate: DateFormat("yyyy-MM-dd").format(endDate),
          );
        });
      }
    } catch (ex) {
      //log(ex.toString());
    }
  }

  Widget buildSummaryItem(BuildContext context, WeeklySummaryData summary) {
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
                "Date: ${DateFormat("yyyy-MMM-dd").format(summary.date)}",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text("Total Orders: ${summary.count}"),
              Text(
                  "Total Distance: ${summary.distance.toIntStringConversion()} KMs"),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              navigate(
                context,
                route: NavigationConstants.dailySummaryRoute,
                extra: DateFormat("yyyy-MM-dd").format(summary.date),
              );
            },
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

  _chipBody({
    required String label,
    VoidCallback? cancelClicked,
    required bool isSelected,
    IconData? cancelIcon,
    IconData? icon,
    required bool needsLabel,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        right: 4.1.w * 2,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1.sw * .5,
        ),
        decoration: needsLabel
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                color: isSelected
                    ? AppColors.primaryColor
                    : const Color(0xffF0F0F0),
              )
            : const BoxDecoration(
                color: Colors.transparent,
              ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(
                  Icons.filter_alt_outlined,
                  size: needsLabel ? 20 : 25,
                  color: !isSelected ? const Color(0xff585858) : Colors.white,
                ),
              ),
            needsLabel
                ? Flexible(
                    child: Text(
                    label,
                    style: TextStyle(
                      color:
                          !isSelected ? const Color(0xff585858) : Colors.white,
                    ),
                  ))
                : const SizedBox(),
            if (cancelIcon != null)
              Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Container(
                  padding: EdgeInsets.only(left: 2.w),
                  decoration: BoxDecoration(
                      border: Border(
                    left: BorderSide(
                      color: Colors.grey,
                      width: 1.w,
                    ),
                  )),
                  child: GestureDetector(
                    onTap: cancelClicked,
                    child: Icon(
                      cancelIcon,
                      size: 20,
                      color:
                          !isSelected ? const Color(0xff585858) : Colors.white,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
