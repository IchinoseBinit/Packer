// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:pinput/pinput.dart';
// import 'package:provider/provider.dart';

// import 'package:packer/constants/app_colors.dart';
// import 'package:packer/constants/navigation_constants.dart';
// import 'package:packer/controllers/services/navigate.dart';
// import 'package:packer/features/views/auth/provider/home_provider.dart';
// import 'package:packer/features/views/order/models/see_order_details_packer.dart';
// import 'package:packer/features/views/order/provider/order_provider.dart';
// import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
// import 'package:packer/features/views/widgets/general_appbar.dart';
// import 'package:packer/features/views/widgets/general_elevated_button.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   final OrderDetailModel order;

//   const OtpVerificationScreen({
//     super.key,
//     required this.order,
//   });

//   @override
//   State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
// }

// class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   final TextEditingController otpController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const GeneralAppBar(
//         middleWidget: Text("OTP Verification"),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: 16.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               SizedBox(height: 30.h),
//               Center(
//                 child: Text(
//                   "Please enter the OTP",
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontSize: 16.sp,
//                         color: AppColors.cartTextColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                 ),
//               ),
//               Pinput(
//                 length: 4,
//                 controller: otpController,
//                 keyboardType: TextInputType.number,
                
//                 defaultPinTheme: PinTheme(
//                   height: 48.h,
//                   width: 45.w,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.black12),
//                   ),
//                 ),
//                 focusedPinTheme: PinTheme(
//                   height: 48.h,
//                   width: 45.w,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.black),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 40.h),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).padding.bottom + 24.h,
//           left: 16.w,
//           right: 16.w,
//         ),
//         child: GeneralElevatedButton(
//           title: "Submit",
//           onPressed: () async {
//             debugger();
//             final otp = otpController.text.trim();
//             if (otp.isEmpty || otp.length < 4) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                     content: Text("Please enter a valid 4-digit OTP")),
//               );
//               return;
//             }

//             showLoading(context);

//             final parsedOrderId =
//                 int.tryParse(widget.order.data.id.toString()) ?? 0;

//             final success = await Provider.of<OrderProvider>(
//               context,
//               listen: false,
//             ).productPost(
//               context,
//               parsedOrderId,
//               otp,
//             );

//             if (!mounted) return;

//             removeLoading(context);

//             if (success) {
//               Provider.of<HomeProvider>(context, listen: false)
//                   .fetchLatestOrders();

//               navigateAndRemoveAll(
//                 context,
//                 route: NavigationConstants.dashboardRoute,
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
