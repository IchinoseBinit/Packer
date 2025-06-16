import 'dart:ui';

// import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
  final CommonProductModel productModel;
  final double? width;
  final Function()? onTap;
  final ItemStatus status;
  final int? quantity;

  const ProductCard({
    super.key,
    required this.productModel,
    this.width,
    this.onTap,
    required this.status,
    this.quantity,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onTap?.call();
      },
      // child: Stack(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: widget.width ?? 140.w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: widget.status == ItemStatus.remaining
                    ? Colors.white
                    : Colors.green,
                border: Border.all(
                  color: widget.status == ItemStatus.remaining
                      ? AppColors.homeScreenTopBgColor
                      : Colors.green,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      SizedBox(height: 4.h),
                      AspectRatio(
                        aspectRatio: 0.9,
                        child: ClipRRect(
                          child: Stack(
                            children: [
                              widget.productModel.image.isNotEmpty
                                  ? Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        // gradient: LinearGradient(colors: [
                                        //   AppColors.homeScreenTopBgColor.withAlpha(75),
                                        //   AppColors.homeScreenTopBgColor,
                                        // ]),
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: CachedNetworkImage(
                                          imageUrl: widget.productModel.image,
                                          width: widget.width ?? 140.w,
                                          fit: BoxFit.contain,
                                          errorWidget:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                            child:
                                                Icon(Icons.image_not_supported),
                                          ),
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator
                                                          .adaptive()),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                      Icons.image_not_supported,
                                    )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: 42.h,
                            child: Text(
                              widget.productModel.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                    color: widget.status == ItemStatus.remaining
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          widget.productModel.size != "0"
                              ? "${widget.productModel.size} ${widget.productModel.measurement}"
                              : "",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: widget.status == ItemStatus.remaining
                                        ? AppColors.homeScreenDimTextColor
                                        : Colors.white,
                                    fontSize: 9.sp,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // 4.h
                  SizedBox(height: 4.h),
                  if (widget.status == ItemStatus.remaining)
                    Container(
                      height: 28.h,
                      alignment: Alignment.center,
                      child: Text(
                        "Remaining: ${widget.quantity ?? (widget.productModel.quantity - widget.productModel.scannedCount)}",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                    )
                  else
                    Container(
                      height: 28.h,
                      alignment: Alignment.center,
                      child: Text(
                        "Done",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ),

                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
