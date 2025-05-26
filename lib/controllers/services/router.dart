import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/views/low_stock_details.dart';
import 'package:packer/features/views/low_stock/views/low_stock_scanner.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/order/models/cart_item.dart';
import 'package:packer/features/views/packer_transfer/views/basket_list.dart';
import 'package:packer/features/views/product/product_scanner.dart';
import 'package:packer/features/views/bucket/bucket_scan.dart';
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
import 'package:packer/features/views/profile/profile_screen.dart';
import 'package:packer/features/views/scan/rack_scan_screen.dart';
import 'package:packer/features/views/scan/scan_screen.dart';
import 'package:packer/features/views/summary/views/daily_summary_screen.dart';
import 'package:packer/features/views/summary/views/summary_screen.dart';
import 'package:packer/features/views/widgets/after_delivery.dart';

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
              GoRoute(
                path: NavigationConstants.bucketqrScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final orderId = state.extra as String;

                  return BucketScanScreen(
                    orderId: orderId,
                  );
                },
              ),
              GoRoute(
                path: NavigationConstants.productqrScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  final extra = state.extra as Map<String, dynamic>?;

                  // final bool cartItem = extra?['cartItem'] as bool;
                  final productId =
                      extra?['productId']; // Assuming it's int or string

                  return ProductScannerScreen(
                    productId: [productId],
                    isfromCartItem: true,

                    // Ensure it's a list
                    // isfromCartItem: cartItem,
                  );
                },
              ),
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
              GoRoute(
                path: NavigationConstants.citizenshipCardScreenRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const CitizenshipSelection();
                },
              ),
              GoRoute(
                path: NavigationConstants.orderDetailsRoute,
                builder: (BuildContext context, GoRouterState state) {
                  // var orderId = '3485';
                  final orderId = state.extra as String;

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
                    rack: data['rack'] ?? '',
                    updateRack: data['updateRack'] ?? false,
                    productId: data['productId'] ?? 0,
                    cartonProduct: data['cartonProduct'] ?? false,
                    message: data['message'] ?? '',
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
                path: NavigationConstants.afterDeliveryRoute,
                builder: (BuildContext context, GoRouterState state) {
                  return const DeliveredPage(
                    noOfItems: 1,
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
