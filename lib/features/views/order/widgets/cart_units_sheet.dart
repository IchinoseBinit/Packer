import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';

/// Bottom sheet: cart product summary + unit tags, then scan navigation.
class CartUnitsSheet extends StatelessWidget {
  const CartUnitsSheet({super.key, required this.product});

  final ProductDetails product;

  static Future<void> open(BuildContext context,
      {required ProductDetails product}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CartUnitsSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final units = product.unitsToScan ?? const [];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  _chip(Icons.inventory_2_outlined, 'Qty: ${product.quantity}'),
                  _chip(Icons.qr_code_2, 'Units: ${units.length}'),
                  if (product.rackName.isNotEmpty)
                    _chip(Icons.shelves, product.rackName),
                ],
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onPressed: units.isEmpty
                      ? null
                      : () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop(); // close sheet
                          navigateWithRouter(
                            router,
                            route: NavigationConstants.cartItemScanScreenRoute,
                            extra: {'productId': product.id},
                          );
                        },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Tags'),
                ),
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: units.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: const Center(child: Text('No units')),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: units.length,
                        separatorBuilder: (_, __) => SizedBox(height: 6.h),
                        itemBuilder: (context, index) {
                          final tag = units[index].tag;
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_2, size: 18.r),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(tag,
                                      style: TextStyle(fontSize: 13.sp)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    return Builder(builder: (context) {
      final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.r, color: c),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: c)),
        ],
      );
    });
  }
}
