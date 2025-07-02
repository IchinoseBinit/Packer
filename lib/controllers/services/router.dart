import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/carton/carton_list_screen.dart';
import 'package:packer/features/views/low_stock/views/low_stock_details.dart';
import 'package:packer/features/views/low_stock/views/low_stock_scanner.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/packer_transfer/views/basket_list.dart';
import 'package:packer/features/views/product/product_list_screen.dart';
import 'package:packer/features/views/product/product_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/features/views/auth/views/login_screen.dart';
import 'package:packer/features/views/auth/views/splash_screen.dart';
import 'package:packer/features/views/auth/views/welcome_screen.dart';
import 'package:packer/features/views/document/views/citizenship.dart';
import 'package:packer/features/views/document/views/document_list_screen.dart';
import 'package:packer/features/views/document/views/driving_license.dart';
import 'package:packer/features/views/document/views/photos_of_location.dart';
import 'package:packer/features/views/home/thank_you_page.dart';
import 'package:packer/features/views/navigation/navigation_page.dart';
import 'package:packer/features/views/order/views/order_detail_page.dart';
import 'package:packer/features/views/order/views/unsettled_orders_screen.dart';
import 'package:packer/features/views/order/views/view_image_screen.dart';
import 'package:packer/features/views/packer_transfer/views/transfer_item.dart';
import 'package:packer/features/views/packer_transfer/views/transfer_list.dart';
import 'package:packer/features/views/product/unit_verify_scanner.dart';
import 'package:packer/features/views/profile/profile_screen.dart';
import 'package:packer/features/views/profile/update_rack_screen.dart';
import 'package:packer/features/views/scan/scan_screen.dart';
import 'package:packer/features/views/scanner/views/basket_scan_screen.dart';
import 'package:packer/features/views/scanner/views/cart_item_scan_screen.dart';
import 'package:packer/features/views/scanner/views/carton_scan_screen.dart';
import 'package:packer/features/views/scanner/views/damaged_scan_screen.dart';
import 'package:packer/features/views/scanner/views/identifier_scan_screen.dart';
import 'package:packer/features/views/scanner/views/product_scan_screen.dart';
import 'package:packer/features/views/scanner/views/rack_scan_screen.dart';
import 'package:packer/features/views/stock_verification/views/stock_rack_scan_screen.dart';
import 'package:packer/features/views/stock_verification/views/stock_verification_screen.dart';
import 'package:packer/features/views/stock_verification/views/store_selection_screen.dart';
import 'package:packer/features/views/summary/views/daily_summary_screen.dart';
import 'package:packer/features/views/summary/views/summary_screen.dart';

class AppRouter {
  static late GoRouter router;
  static late BuildContext context;
  GoRouter getRoutes(BuildContext context) {
    router = GoRouter(
      initialLocation: NavigationConstants.initialRoute,
      routes: <RouteBase>[
        GoRoute(
            path: NavigationConstants.initialRoute,
            builder: (BuildContext context, GoRouterState state) {
              return const SplashScreen();
            },
            routes: <RouteBase>[
              GoRoute(
                path: NavigationConstants.welcomeScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const WelcomeScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.loginRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const LoginScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.dashboardRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const NavigationScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.documentListScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const DocumentListScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.photoSelectionRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const PhotoSelection();
                },
              ),
              GoRoute(
                path: NavigationConstants.profileScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return ProfileScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.thankYouPageRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return ThankYouPage();
                },
              ),
              // GoRoute(
              //   path: NavigationConstants.bucketqrScreenRoute,
              //   builder: (BuildContext context, GoRouterState state) {
              //     final orderId = state.extra as String;

              //     return BucketScanScreen(
              //       orderId: orderId,
              //     );
              //   },
              // ),
              // GoRoute(
              //   path: NavigationConstants.productqrScreenRoute,
              //   builder: (BuildContext context, GoRouterState state) {
              //     final extra = state.extra as Map<String, dynamic>?;

              //     final productId =
              //         extra?['productId']; // Assuming it's int or string

              //     return ProductScannerScreen(
              //       productId: productId,
              //     );
              //   },
              // ),
              GoRoute(
                path: NavigationConstants.photoSelectionRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const PhotoSelection();
                },
              ),

              GoRoute(
                path: NavigationConstants.drivingLicenseScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const DrivingLicenseSelection();
                },
              ),

              // GoRoute(
              //   path: NavigationConstants.otpScreen,
              //   builder: (BuildContext context, GoRouterState state) {
              //     final order = state.extra as OrderDetailModel;

              //     // final map = state.extra as Map<String, dynamic>;
              //     // final order = map['order'] as OrderDetailModel;

              //     return OtpVerificationScreen(
              //       order: order,
              //     );
              //   },
              // ),
              GoRoute(
                path: NavigationConstants.citizenshipCardScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const CitizenshipSelection();
                },
              ),

              GoRoute(
                path: NavigationConstants.cartonListScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final productId = state.extra as int;
                  return CartonListScreen(
                    productId: productId,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.orderDetailsRoute,
                builder: (BuildContext context, GoRouterState state) {
                  // var orderId = '3485';
                  final orderId = state.extra.toString();

                  log(orderId, name: "order id:");

                  return OrderDetails(
                    orderId: orderId,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.basketListRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return BasketList();
                },
              ),
              GoRoute(
                path: NavigationConstants.scanRackRoute,
                builder: (BuildContext context, GoRouterState state) {
                  // var orderId = '3485';
                  final data = state.extra as Map<String, dynamic>;

                  log(data.toString(), name: "scanRackRoute");

                  return RackScanScreen(
                    rackCode: data['rack'],
                    productId: data['productId'] ?? 0,
                    forCarton: data['forCarton'] ?? false,
                    // updateRack: data['updateRack'] ?? false,
                    // cartonProduct: data['cartonProduct'] ?? false,
                    // message: data['message'] ?? '',
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.lowStockRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return HomeWarehouseScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.lowStockDetailRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return LowStockDetails();
                },
              ),
              GoRoute(
                path: NavigationConstants.lowStockScannerRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  final forProduct = args['forProduct'] ?? false;
                  return LowStockScanner(
                    forProduct: forProduct,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.viewImageRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final imageUrl = state.extra as String;
                  return ViewImageScreen(
                    imageUrl: imageUrl,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.qrScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return ScanScreen(
                    isfromCartItem: args['forCartitem'] ?? false,
                    isFromPackerTransfer: args['forTranfer'] ?? false,
                    checkIdentifier: args['checkIdentifier'] ?? false,
                    scanCarton: args['scanCarton'] ?? false,
                    productId: args['productId'] ?? 0,
                    message: args['message'] ?? '',
                    forBasket: args['forBasket'] ?? false,
                    isLowStockCarton: args['isLowStockCarton'] ?? false,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.unsettledOrdersRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const UnsettledOrdersScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.weeklySummaryRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const SummaryScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.dailySummaryRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final extra = state.extra as String;
                  return DailySummaryScreen(startDate: extra.toString());
                },
              ),
              GoRoute(
                path: NavigationConstants.transferListRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const TransferList();
                },
              ),
              GoRoute(
                path: NavigationConstants.transferDetailsRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const TransferItemsList();
                },
              ),
              GoRoute(
                path: NavigationConstants.stockVerificationRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return StockVerificationScreen(
                      storeId: state.extra as String);
                },
              ),
              GoRoute(
                path: NavigationConstants.storeSelectionRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return StoreSelectionScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.basketScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return BasketScanScreen(
                    basketCode: args['basketCode'],
                    forOrder: args['forOrder'] ?? false,
                    fromCall: args['fromCall'] ?? false,
                    orderId: args['orderId'].toString().toInt(),
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.cartItemScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return CartItemScanScreen(
                    productId: args['productId'] ?? 0,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.inventoryScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return IdentifierScanScreen(
                    identifier: args['identifier'] ?? '',
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.productScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return ProductScanScreen(
                    productId: args['productId'] ?? 0,
                    fromStockVerification:
                        args['fromStockVerification'] ?? false,
                    cartonId: args['cartonId'],
                    fromTransfer: args['forTransfer'] ?? false,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.cartonScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};

                  return CartonScanScreen(
                    cartonId: args['cartonId'] as int?,
                    fromVerification: args['fromVerification'] ?? false,
                    isMainStoreAudit: args['isMainStoreAudit'] ?? false,
                    cartonCode: args['code'],
                    tag: args['tag'],
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.rackUpdateScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return UpdateRackScreen(productId: args['productId']);
                },
              ),
              GoRoute(
                path: NavigationConstants.productListScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return ProductListScreen();
                },
              ),
              GoRoute(
                path: NavigationConstants.stockRackScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return StockRackScanScreen(
                    changeRack: args['changeRack'] ?? false,
                  );
                },
              ),

              GoRoute(
                path: NavigationConstants.unitVerifyScannerRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return UnitVerifyScanner(
                    reScan: args['reScan'] ?? false,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.unitProductScannerRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return UnitProductScannerScreen(
                    showInfo: args['showInfo'] ?? false,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.damageScanScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final args = state.extra as Map<String, dynamic>? ?? {};
                  return DamagedScanScreen(
                    showInfo: args['showInfo'] ?? false,
                  );
                },
              ),
            ]),
      ],
    );
    context = context;
    return router;
  }
}
