import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class CartonListScreen extends StatelessWidget {
  final int productId;
  const CartonListScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: GeneralAppBar(
        backgroundColor: AppColors.fillColor,
        middleWidget: Text(
          'Carton List',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: FutureBuilder(
        future: Provider.of<StockVerificationProvider>(context, listen: false)
            .fetchCartonList(context, productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: AppConstants.padding,
            child: Consumer<StockVerificationProvider>(
                builder: (context, value, child) {
              if (value.cartonList.isEmpty) {
                return Column(
                  children: [
                    SizedBox(
                      height: .2.sh,
                    ),
                    Text(
                      "No Cartons left",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    SizedBox(
                      height: .45.sh,
                    ),
                    GeneralElevatedButton(
                        title: "Complete",
                        onPressed: () {
                          Provider.of<StockVerificationProvider>(context,
                                  listen: false)
                              .completeCarton();
                          navigatePop(context);
                        }),
                  ],
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<StockProvider>(context, listen: false)
                      .fetchCartonList(context, productId);
                },
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) => SizedBox(
                          height: 8.h,
                        ),
                        itemCount: value.cartonList.length,
                        itemBuilder: (context, index) {
                          final carton = value.cartonList[index];
                          return InkWell(
                            onTap: () {
                              Provider.of<StockVerificationProvider>(context,
                                      listen: false)
                                  .setSelectedCarton(carton);

                              navigate(context,
                                  route:
                                      NavigationConstants.cartonScanScreenRoute,
                                  extra: {
                                    'cartonId': carton.id,
                                    'fromVerification': true,
                                    'code': carton.uniqueIdentifier,
                                  });
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: primaryColor.withOpacity(0.4),
                                    width: 1),
                              ),
                              child: ListTile(
                                title: Text(carton.uniqueIdentifier,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        )),
                                subtitle: Text('ID: ${carton.id}'),
                                trailing: Text(
                                  carton.isScanned ? 'Scanned' : 'Not Scanned',
                                  style: TextStyle(
                                    color: carton.isScanned
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    GeneralElevatedButton(
                        title: "Scan Carton",
                        onPressed: () {
                          navigate(context,
                              route: NavigationConstants.cartonScanScreenRoute,
                              extra: {
                                'cartonId': 0,
                                'fromVerification': true,
                              });
                        }),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
