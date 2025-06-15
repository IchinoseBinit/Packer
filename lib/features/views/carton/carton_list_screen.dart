import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class CartonListScreen extends StatelessWidget {
  final int productId;
  const CartonListScreen({super.key, required this.productId});

  void initState(BuildContext context) {
    debugger();
    Provider.of<StockProvider>(context, listen: false)
        .fetchCartonList(context, productId);
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
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.separated(
            separatorBuilder: (context, index) => SizedBox(
              height: 8.h,
            ),
            itemCount: value.cartonList.length,
            itemBuilder: (context, index) {
              final carton = value.cartonList[index];
              return InkWell(
                onTap: () {
                  navigate(context,
                      route: NavigationConstants.cartonScanScreenRoute);
                },
                child: ListTile(
                  title: Text(carton.uniqueIdentifier),
                  subtitle: Text('ID: ${carton.id}'),
                  trailing: Text(
                    carton.status,
                    style: TextStyle(
                      color:
                          carton.status == 'active' ? Colors.green : Colors.red,
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
