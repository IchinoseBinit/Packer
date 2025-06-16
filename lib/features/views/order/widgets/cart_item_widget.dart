// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:packer/features/views/order/models/cart_item.dart';
// import '/constants/app_colors.dart';

// class CartItemWidget extends StatelessWidget {
//   final CartItem cartItem;
//   const CartItemWidget({
//     super.key,
//     required this.cartItem,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: AppColors.backgroundColor,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   height: 60.h,
//                   width: 60.h,
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: cartItem.productImage.isNotEmpty
//                         ? Image.network(
//                             cartItem.productImage,
//                             fit: BoxFit.contain,
//                             errorBuilder: (context, error, stackTrace) =>
//                                 const Icon(Icons.image_not_supported),
//                           )
//                         : const Icon(Icons.image_not_supported),
//                   ),
//                 ),
//               ),
//               SizedBox(
//                 width: 8.w,
//               ),
//               Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(
//                     width: .3.sw,
//                     child: Text(
//                       cartItem.productName,
//                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             fontWeight: FontWeight.w600,
//                           ),
//                       textAlign: TextAlign.start,
//                     ),
//                   ),
//                   Text(
//                     "${cartItem.size} ${cartItem.measurement}",
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: AppColors.homeScreenDimTextColor,
//                         ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           Text(
//             "Qty: ${cartItem.quantity}",
//             style: TextStyle(
//               fontSize: 16.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
