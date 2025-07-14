import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: widget.width ?? 140.w,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                border: Border.all(
                  color: AppColors.productCardBorderColor,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 30.h,
                          child: Text(
                            widget.productModel.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  color: Colors.black,
                                ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Qty: ${widget.productModel.quantity != 0 ? widget.productModel.quantity : widget.productModel.productUnits.length}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.homeScreenDimTextColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              widget.productModel.size != "0"
                                  ? "${widget.productModel.size} ${widget.productModel.measurement}"
                                  : "",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.homeScreenDimTextColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),

                  /// Remaining or Packed badge
                  if (widget.status == ItemStatus.remaining)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        height: 30.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.h),
                          color: AppColors.primaryColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Remaining: ${widget.quantity ?? (widget.productModel.quantity - widget.productModel.scannedCount)}",
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 4),
                      child: Container(
                        height: 28.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.h),
                          color: AppColors.green700,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.white, size: 16.sp),
                              SizedBox(width: 4.w),
                              Text(
                                "Packed",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
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

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:packer/constants/app_colors.dart';
// import 'package:packer/features/views/product/model/common_product_model.dart';
// import 'package:packer/features/views/order/widgets/cart_items_list.dart';

// class ProductCard extends StatefulWidget {
//   final CommonProductModel productModel;
//   final double? width;
//   final Function()? onTap;
//   final ItemStatus status;
//   final int? quantity;

//   const ProductCard({
//     super.key,
//     required this.productModel,
//     this.width,
//     this.onTap,
//     required this.status,
//     this.quantity,
//   });

//   @override
//   State<ProductCard> createState() => _ProductCardState();
// }

// class _ProductCardState extends State<ProductCard> {
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: () {
//         widget.onTap?.call();
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           SizedBox(
//             width: widget.width ?? 164.w,
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 color: Colors.white,
//                 border: Border.all(
//                   color: AppColors.productCardBorderColor,
//                   width: 1.0,
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Column(
//                     children: [
//                       SizedBox(height: 4.h),
//                       AspectRatio(
//                         aspectRatio: 0.9,
//                         child: ClipRRect(
//                           child: Stack(
//                             children: [
//                               widget.productModel.image.isNotEmpty
//                                   ? Container(
//                                       margin: const EdgeInsets.symmetric(
//                                         vertical: 4,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: Align(
//                                         alignment: Alignment.center,
//                                         child: CachedNetworkImage(
//                                           imageUrl: widget.productModel.image,
//                                           width: widget.width ?? 140.w,
//                                           fit: BoxFit.contain,
//                                           errorWidget:
//                                               (context, error, stackTrace) =>
//                                                   const Center(
//                                             child:
//                                                 Icon(Icons.image_not_supported),
//                                           ),
//                                           placeholder: (context, url) =>
//                                               const Center(
//                                                   child:
//                                                       CircularProgressIndicator
//                                                           .adaptive()),
//                                         ),
//                                       ),
//                                     )
//                                   : const Center(
//                                       child: Icon(
//                                       Icons.image_not_supported,
//                                     )),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 4.h),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         SizedBox(
//                           height: 26.h,
//                           child: Text(
//                             widget.productModel.productName,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .headlineSmall
//                                 ?.copyWith(
//                                   fontSize: 12.sp,
//                                   fontWeight: FontWeight.w600,
//                                   height: 1.2,
//                                   color: Colors.black,
//                                 ),
//                           ),
//                         ),
//                         SizedBox(height: 8.h),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "Qty: ${widget.productModel.quantity}",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium
//                                   ?.copyWith(
//                                     color: AppColors.homeScreenDimTextColor,
//                                     fontSize: 12.sp,
//                                     fontWeight: FontWeight.w400,
//                                   ),
//                             ),
//                             SizedBox(width: 4.w),
//                             Text(
//                               widget.productModel.size != "0"
//                                   ? "${widget.productModel.size} ${widget.productModel.measurement}"
//                                   : "",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium
//                                   ?.copyWith(
//                                     color: AppColors.homeScreenDimTextColor,
//                                     fontSize: 12.sp,
//                                     fontWeight: FontWeight.w400,
//                                   ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 4.h),

//                   /// Remaining or Packed badge
//                   if (widget.status == ItemStatus.remaining)
//                     Padding(
//                       padding: const EdgeInsets.all(12.0),
//                       child: Container(
//                         height: 30.h,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(4.h),
//                           color: AppColors.primaryColor,
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           "Remaining: ${widget.quantity ?? (widget.productModel.quantity - widget.productModel.scannedCount)}",
//                           textAlign: TextAlign.center,
//                           style:
//                               Theme.of(context).textTheme.bodySmall?.copyWith(
//                                     color: Colors.white,
//                                     fontSize: 12.sp,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                         ),
//                       ),
//                     )
//                   else ...[
//                     Builder(
//                       builder: (context) {
//                         // WidgetsBinding.instance.addPostFrameCallback((_) {
//                         //   Provider.of<ProductProvider>(context, listen: false)
//                         //       .incrementPackedOnce(widget.productModel.id);
//                         // });

//                         return Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12.0, vertical: 4),
//                           child: Container(
//                             height: 28.h,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(4.h),
//                               color: AppColors.green700,
//                             ),
//                             child: Center(
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(Icons.check_circle,
//                                       color: Colors.white, size: 16.sp),
//                                   SizedBox(width: 4.w),
//                                   Text(
//                                     "Packed",
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall
//                                         ?.copyWith(
//                                           color: Colors.white,
//                                           fontSize: 12.sp,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],

//                   SizedBox(height: 8.h),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
