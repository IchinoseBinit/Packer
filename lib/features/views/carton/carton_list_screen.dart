import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class CartonListScreen extends StatefulWidget {
  final int productId;

  const CartonListScreen({super.key, required this.productId});

  @override
  State<CartonListScreen> createState() => _CartonListScreenState();
}

class _CartonListScreenState extends State<CartonListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<StockProvider>(context, listen: false)
        .fetchCartonList(context, widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: Text(
          'Carton List',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: Consumer<StockProvider>(
        builder: (context, value, child) {
          if (value.cartonList.isEmpty) {
            return const Center(child: Text('No cartons found.'));
          }

          return ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 6.h),
            itemCount: value.cartonList.length,
            itemBuilder: (context, index) {
              final carton = value.cartonList[index];
              return InkWell(
                onTap: () {
                  navigate(context,
                      route: NavigationConstants.cartonScanScreenRoute);
                },
                child: ListTile(
                  subtitle: Column(
                    children: [
                      Text(carton.uniqueIdentifier),
                      SizedBox(height: 4.h),
                      Text(
                        carton.status,
                      ),
                    ],
                  ),
                  title: Text(
                    'ID: ${carton.id}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
