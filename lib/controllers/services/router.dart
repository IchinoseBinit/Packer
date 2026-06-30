import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/extensions/debug_print_extension.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/controllers/services/route_observer.dart';
import 'package:packer/features/views/carton/carton_list_screen.dart';
import 'package:packer/features/views/damage_products/damage_product_list.dart';
import 'package:packer/features/views/damage_products/rack_product_list.dart';
import 'package:packer/features/views/driver/model/driver_transfer_model.dart';
import 'package:packer/features/views/driver/views/basket_list_screen.dart';
import 'package:packer/features/views/driver/views/driver_basket_scanner.dart';
import 'package:packer/features/views/driver/views/driver_home_screen.dart';
import 'package:packer/features/views/driver/views/in_transit_screen.dart';
import 'package:packer/features/views/expiry_product/screens/expired_products_screen.dart';
import 'package:packer/features/views/audit_product/screens/audit_product_screen.dart';
import 'package:packer/features/views/fruits_vegs/screens/fruits_vegs_screen.dart';
import 'package:packer/features/views/inventory_transfer_main_store/views/inventory_transfer_basket_list.dart';
import 'package:packer/features/views/inventory_transfer_main_store/views/inventory_transfer_items.dart';
import 'package:packer/features/views/inventory_transfer_main_store/views/inventory_transfer_list.dart';
import 'package:packer/features/views/inventory_transfer_main_store/views/inventory_transfer_scanner.dart';
import 'package:packer/features/views/inventory_transfer_request/views/inventory_transfer_request.dart';
import 'package:packer/features/views/inventory_transfer_request/views/inventory_transfer_request_item.dart';
import 'package:packer/features/views/inventory_transfer_request/views/inventory_transfer_request_scanner.dart';
import 'package:packer/features/views/inventory_transfer_request/views/transfer_request_trolley_item.dart';
import 'package:packer/features/views/leave_request/screens/leave_request_screen.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/views/collected_product_view.dart';
import 'package:packer/features/views/low_stock/views/low_stock_details.dart';
import 'package:packer/features/views/low_stock/views/low_stock_product_detail_screen.dart';
import 'package:packer/features/views/low_stock/views/low_stock_scanner.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/low_stock/views/trolley_item_screen.dart';
import 'package:packer/features/views/low_stock/views/trolley_scan_screen.dart';
import 'package:packer/features/views/order/views/order_return_detail.dart';
import 'package:packer/features/views/order/views/order_return_list.dart';
import 'package:packer/features/views/order/views/order_return_scanner.dart';
import 'package:packer/features/views/package_return/screen/package_return_screen.dart';
import 'package:packer/features/views/package_return/screen/scan_package_return.dart';
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
import 'package:packer/features/views/profile/packer_checkout_scan_screen.dart';
import 'package:packer/features/views/profile/profile_screen.dart';
import 'package:packer/features/views/profile/update_rack_screen.dart';
import 'package:packer/features/views/receive_baskets/view/basket_in_transit.dart';
import 'package:packer/features/views/receive_baskets/view/receive_basket_list.dart';
import 'package:packer/features/views/receive_baskets/view/receive_basket_scanner.dart';
import 'package:packer/features/views/scan/scan_screen.dart';
import 'package:packer/features/views/scanner/views/basket_scan_screen.dart';
import 'package:packer/features/views/scanner/views/cart_item_scan_screen.dart';
import 'package:packer/features/views/scanner/views/carton_scan_screen.dart';
import 'package:packer/features/views/scanner/views/damaged_scan_screen.dart';
import 'package:packer/features/views/scanner/views/ice_pack_scan_screen.dart';
import 'package:packer/features/views/scanner/views/identifier_scan_screen.dart';
import 'package:packer/features/views/scanner/views/product_scan_screen.dart';
import 'package:packer/features/views/scanner/views/rack_scan_screen.dart';
import 'package:packer/features/views/stock_verification/views/stock_rack_scan_screen.dart';
import 'package:packer/features/views/stock_verification/views/stock_verification_screen.dart';
import 'package:packer/features/views/stock_verification/model/store_model.dart';
import 'package:packer/features/views/stock_verification/views/store_selection_screen.dart';
import 'package:packer/features/views/summary/views/daily_summary_screen.dart';
import 'package:packer/features/views/summary/views/summary_screen.dart';
import 'package:packer/features/views/vendor/screens/vendor_screen.dart';

class AppRouter {
  static late GoRouter router;
  GoRouter getRoutes(BuildContext context) {
    router = GoRouter(
      initialLocation: NavigationConstants.initialRoute,
      navigatorKey: AppConstants.navigatorKey,
      onException: (context, state, exception) {
        'An exception occurred: ${state.fullPath}'.logError();
      },
      observers: [GoRouterObserver()],
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
              path: NavigationConstants.productDamageRequestRoute,
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
                final forDamage = state.extra as bool? ?? false;
                return BasketList(forDamage: forDamage);
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
                  forDamage: data['forDamage'] ?? false,
                  forTransfer: data['forTransfer'] ?? false,
                  needAPICallCarton: data['needAPICallCarton'] ?? false,
                  forDamageRequest: data['forDamageRequest'] ?? false,
                  needGapTime: data['needGapTime'] ?? false,
                  // updateRack: data['updateRack'] ?? false,
                  // cartonProduct: data['cartonProduct'] ?? false,
                  // message: data['message'] ?? '',
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.driverHomeRoute,
              builder: (BuildContext context, GoRouterState state) {
                return DriverHomeScreen();
              },
            ),
            GoRoute(
              path: NavigationConstants.driverTransferDetailsRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>?;
                return BasketListScreen(
                  transferItem: args?['transferItem'] as DriverTransferModel,
                  fromInTransit: args?['fromInTransit'] ?? false,
                );
              },
            ),
            // driverInTransitRoute
            GoRoute(
              path: NavigationConstants.driverInTransitRoute,
              builder: (BuildContext context, GoRouterState state) {
                return InTransitScreen();
              },
            ),
            GoRoute(
              path: NavigationConstants.driverBasketScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                return DriverBasketScanner();
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
                final args = state.extra as LowStockModel?;
                return LowStockDetails(
                  lowStockModel: args,
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.lowStockProductDetailRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>?;
                final rackName = args?['rackName'] as String;
                final productList = args?['productList'];
                return LowStockProductDetailScreen(
                  rackName: rackName,
                  productList: productList,
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.receiveTransferListRoute,
              builder: (BuildContext context, GoRouterState state) {
                return BasketInTransitScreen();
              },
            ),
            GoRoute(
              path: NavigationConstants.receiveBasketScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                return ReceiveBasketScanner(
                  scanIdentifier: extra['scanIdentifier'] ?? false,
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.receiveBasketListRoute,
              builder: (BuildContext context, GoRouterState state) {
                return ReceiveBasketList();
              },
            ),
            GoRoute(
              path: NavigationConstants.trolleyItemScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                return TrolleyScanScreen(
                  productId: state.extra.toString().toInt(),
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.orderReturnScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                final extra = state.extra as Map<String, dynamic>? ?? {};
                return OrderReturnScanner(
                  productId: extra['productId'].toString().toInt(),
                  product: extra['product'].toString().toBool(false),
                  rack: extra['rack'].toString().toBool(false),
                );
              },
            ),
            // collectedProductViewRoute
            GoRoute(
              path: NavigationConstants.collectedProductViewRoute,
              builder: (BuildContext context, GoRouterState state) {
                return CollectedProductView();
              },
            ),
            GoRoute(
              path: NavigationConstants.orderReturnDetailsRoute,
              builder: (BuildContext context, GoRouterState state) {
                return OrderReturnDetail();
              },
            ),
            GoRoute(
              path: NavigationConstants.lowStockScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                final forProduct = args['forProduct'] ?? false;
                final changeBasket = args['changeBasket'] ?? false;
                return LowStockScanner(
                  forProduct: forProduct,
                  changeBasket: changeBasket,
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
              path: NavigationConstants.packerCheckoutScanRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                final forOnlineStatus = args['forOnlineStatus'] ?? false;
                return PackerCheckoutScanScreen(
                    forOnlineStatus: forOnlineStatus);
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
                final args = state.extra as Map<String, dynamic>? ?? {};
                final isDamage = args['isDamage'] ?? false;
                return TransferList(isDamage: isDamage);
              },
            ),
            // GoRoute(
            //   path: NavigationConstants.transferRequestListRoute,
            //   builder: (BuildContext context, GoRouterState state) {
            //     return const TransferRequestList();
            //   },
            // ),

            GoRoute(
              path: NavigationConstants.transferDetailsRoute,
              builder: (BuildContext context, GoRouterState state) {
                return const TransferItemsList();
              },
            ),
            GoRoute(
              path: NavigationConstants.stockVerificationRoute,
              builder: (BuildContext context, GoRouterState state) {
                return StockVerificationScreen(storeId: state.extra as String);
              },
            ),
            GoRoute(
              path: NavigationConstants.trolleyItemScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return TrolleyItemScreen();
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
                  forTransfer: args['forTransfer'] ?? false,
                  orderId: args['orderId'].toString().toInt(),
                  forExpiredProducts: args['forExpiredProducts'] ?? false,
                  tags: args['tags'],
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
              path: NavigationConstants.orderReturnScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                // final args = state.extra as Map<String, dynamic>? ?? {};
                return OrderReturnList();
              },
            ),
            GoRoute(
              path: NavigationConstants.productScanScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return ProductScanScreen(
                  productId: args['productId'] ?? 0,
                  fromStockVerification: args['fromStockVerification'] ?? false,
                  cartonId: args['cartonId'],
                  fromTransfer: args['forTransfer'] ?? false,
                  forCarton: args['forCarton'] ?? false,
                  forDamageTransfer: args['forDamageTransfer'] ?? false,
                  forDamageReceive: args['forDamageReceive'] ?? false,
                  forDamageRequest: args['forDamageRequest'] ?? false,
                  forExpiredProducts: args['forExpiredProducts'] ?? false,
                  tags: args['tags'],
                  needGapTime: args['needGapTime'] ?? false,
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
              path: NavigationConstants.productlistScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return ProductListScreen();
              },
            ),
            GoRoute(
              path: NavigationConstants.damageProductReturnList,
              builder: (BuildContext context, GoRouterState state) {
                return DamageProductList();
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
              path: NavigationConstants.rackProductListScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return RackProductList(
                  forLostItem: args['forLostItem'] ?? false,
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.expiryProductScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return ExpiredProductsScreen();
              },
            ),

            GoRoute(
              path: NavigationConstants.damageScanScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return DamagedScanScreen(
                  showInfo: args['showInfo'] ?? false,
                  qr: args['qr'] ?? false,
                  scanRack: args['scanRack'] ?? false,
                  forLostItem: args['forLostItem'] ?? false,
                );
              },
            ),

            GoRoute(
              path: NavigationConstants.inventoryTransferRequestListRoute,
              builder: (BuildContext context, GoRouterState state) {
                return InventoryTransferRequest();
              },
            ),
            GoRoute(
              path: NavigationConstants.inventoryTransferRequestDetailsRoute,
              builder: (BuildContext context, GoRouterState state) {
                return InventoryTransferRequestItem();
              },
            ),
            GoRoute(
              path: NavigationConstants.inventoryTransferRequestScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return InventoryTransferRequestScanner(
                  scanLocal: args['scanLocal'] ?? false,
                  scanBasket: args['scanBasket'] ?? false,
                );
              },
            ),
            GoRoute(
              path:
                  NavigationConstants.inventoryTrolleyTransferRequestItemRoute,
              builder: (BuildContext context, GoRouterState state) {
                return TransferRequestTrolleyItem();
              },
            ),
            //
            GoRoute(
              path: NavigationConstants.inventoryTransferMainStoreRoute,
              builder: (BuildContext context, GoRouterState state) {
                return InventoryTransferList();
              },
            ),
            GoRoute(
              path: NavigationConstants.inventoryTransferBasketListRoute,
              builder: (BuildContext context, GoRouterState state) {
                return InventoryTransferBasketList();
              },
            ),
            GoRoute(
              path: NavigationConstants.inventoryTransferScannerRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return InventoryTransferScanner(
                  scanBasket: args['scanBasket'] ?? false,
                  scanCarton: args['scanCarton'] ?? false,
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.inventoryTransferItemsRoute,
              builder: (BuildContext context, GoRouterState state) {
                return InventoryTransferItems();
              },
            ),
            GoRoute(
              path: NavigationConstants.searchVendor,
              builder: (BuildContext context, GoRouterState state) {
                return VendorScreen();
              },
            ),
            GoRoute(
              path: NavigationConstants.icePackScanScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return IcePackScanScreen();
              },
            ),
            //
            GoRoute(
              path: NavigationConstants.packageReturnScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return PackageReturnScreen();
              },
            ),
            //
            GoRoute(
              path: NavigationConstants.scanPackageReturnRoute,
              builder: (BuildContext context, GoRouterState state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return ScanPackageReturn(
                  orderId: args['orderId'].toString().toInt(),
                  packageId: args['packageId'].toString(),
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.leaveRequestScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return LeaveRequestScreen();
              },
            ),
            GoRoute(
              path: NavigationConstants.fruitsVegsScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return FruitsVegsScreen(
                  preselectedStore: state.extra as Store?,
                );
              },
            ),
            GoRoute(
              path: NavigationConstants.auditProductScreenRoute,
              builder: (BuildContext context, GoRouterState state) {
                return AuditProductScreen(
                  preselectedStore: state.extra as Store?,
                );
              },
            ),
          ],
        ),
      ],
    );
    return router;
  }
}
