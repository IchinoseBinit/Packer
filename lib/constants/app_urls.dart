import 'package:packer/enum/environment_config.dart';

class AppUrls {
  static String baseUrl = EnvironmentConfig.type == EnvironmentType.staging
      ? "http://103.187.8.105:8000" // or any sensible default
      : "https://api.fasto.com.np";

  static void setBaseUrl(String url) {
    if (EnvironmentConfig.type == EnvironmentType.staging) {
      baseUrl = url;
    } else {
      baseUrl = "https://api.fasto.com.np";
    }
  }
  // static const String _productionDomainUrl = "fasto.com.np";
  // static const String _stagingDomainUrl = "103.187.8.105:8000";

  // static String get baseUrl => EnvironmentConfig.when(
  //       production: "https://$_productionDomainUrl",
  //       staging: "http://$_stagingDomainUrl",
  //     );

  // static const String _domainUrl = "13.211.205.215:8000";

  // static const String _domainUrl = "192.168.1.73:8000";
  // static const String _domainUrl = "192.168.100.183:8000";
  // static const String baseUrl = "http://$_domainUrl";

  // static const String _domainUrl = "dropit.com.np";
  // static const String baseUrl = "https://$_domainUrl";
  // static const String baseUrl = "https://dropit.com.np";

  static String get imageUrl =>
      EnvironmentConfig.type == EnvironmentType.staging
          ? baseUrl
          : "https://cdn.fasto.com.np";

  static String get _authUrl => "$baseUrl/auth";

  // static  String registerUrl => "$_authUrl/register";
  static String get loginUrl => "$_authUrl/api/token/";
  static String get verifyOtpUrl => "$_authUrl/verify-otp";
  static String get refreshTokenUrl => "$_authUrl/verify-otp/refresh";
  static String get logoutUrl => "$_authUrl/logout";

  // Category
  static String get categoryUrl => "$baseUrl/categories";
  static String get subcategoryUrl => "$baseUrl/subcategories";
  static String get productUrl => "$baseUrl/products";
  //static  String get productImageUrl => "$baseUrl/products/image"; productimage/
  static String get productImageUrl => "$baseUrl/product/productimage";
  //http://13.211.205.215:8000/admin/product/productimage/
  static String get cartUrl => "$baseUrl/cart-items";
  // static  String get increamentCartUrl => "$baseUrl/cart-items";

  static String get damageProductImageUpload =>
      "$baseUrl/damaged-products/upload/";

  //login api path
  static String get loginUrldemo => "$_authUrl/api/token/";

  static String get _packerUrl => "$baseUrl/staff/packer";

  static String get orderUrl => "$baseUrl/orders";

  static String get orderDetailsUrl => "$orderUrl/id/rider-detail";
  static String get acknowledgeOrderUrl => "$baseUrl/staff/orders";
  static String get billOrderUrl => "$orderUrl/id/bill";
  //
  static String get orderQrImageUrl => "$orderUrl/view-qr";
  static String get homeImageUrl => "$orderUrl/id/home-image";

  static String get productPostDetail => "$orderUrl/basket-order/";

  static String get packerOnlineStatus =>
      "$baseUrl/staff/packer/online-status/";
  static String get packerSummaryUrl => "$_packerUrl/summary/";
  static String get packerStoreLocationUrl => "$_packerUrl/store-location";

  // checkout before logout (scan warehouse QR)
  static String get packerCheckoutLogoutUrl =>
      "$baseUrl/staff/warehouse-packer/logout/";

  static String get packerAvailability => "$baseUrl/staff/packer/availability/";

  static String get getOrdersByStatusUrl => "$orderUrl/get-order?status=";
  static String get getLatestOrdersUrl => "$orderUrl/get-order";
  static String get getUnsettledOrdersUrl => "$_packerUrl/unsettled-orders";
  static String get createSettlementRequestUrl =>
      "$_packerUrl/create-settlement-request";
  static String get orderSummaryUrl => "$_packerUrl/weekly-summary/";
  static String get dailySummaryUrl => "$_packerUrl/order-view/";

  static String get fcmTokenUrl => "$baseUrl/notification/register-device";

  // packer_transfer
  static String get packerTransferUrl => "$baseUrl/packer/transfers/";
  static String get packerTransferDetailsUrl => "$baseUrl/packer/transfers/id/";
  // scan-unit
  static String get scanUnitUrl => "$baseUrl/packer/transfers/id/scan-units/";
  // complete
  static String get completeTransferUrl =>
      "$baseUrl/packer/transfers/id/complete/";

  // low-stock
  static String get lowStockUrl => "$baseUrl/packer/low-stock-products/";

  static String get lowStockForWareHouseUrl =>
      "$baseUrl/packer/low-stock/stores/";

  static String get getVendors => "$baseUrl/packer/vendors/";

  static String get productByStoreAndVendor =>
      "$baseUrl/packer/low-stock/stores/SID/products/";

  // manager_transfer
  static String get managerTransferUrl => "$baseUrl/store/transfers/";
  static String get managerTransferDetailsUrl => "$baseUrl/store/transfers/id/";
  // verify-units
  static String get verifyUnitsUrl =>
      "$baseUrl/store/transfers/id/verify-units/";

  static String get verifyDamageProductUrl =>
      "$baseUrl/transfers/id/receive-damaged-units/";
  // updateRackUrl
  static String get updateRackUrl =>
      "$baseUrl/update-product-availabilty-rack/";
  // accept
  static String get acceptTransferUrl => "$baseUrl/store/transfers/id/accept/";

  static String get basketClearUrl => "$orderUrl/clear-basket/";

  static String get orderReturnUrl =>
      "$baseUrl/staff/order-cancel-request-list/";
  // clear-cancelled-basket
  static String get clearCancelledBasketUrl =>
      "$baseUrl/staff/clear-cancelled-basket/";

  //transfer request
  static String get transferRequestUrl =>
      "$baseUrl/inventory-transfer-requests/";
  static String get transferRequestDetailsUrl =>
      "$baseUrl/inventory-transfer-requests/id/";

  // staff/scan-basket
  static String get scanBasketUrl => "$baseUrl/staff/scan-basket/";

  // add-products
  static String get addProductsUrl => "$baseUrl/staff/add-products/";
  // transfer-basket-inventory/
  static String get transferBasketInventoryUrl =>
      "$baseUrl/staff/transfer-basket-inventory/";

  // carton_info/<str:carton_identifier>/
  static String get cartonInfoUrl => "$baseUrl/carton_info/:id/";
  static String get cartonListUrl => "$baseUrl/cartons/product_id";
  // carton-detail/<int:carton_id>/
  static String get cartonDetailUrl => "$baseUrl/carton-detail/:id/";
  static String get cartonByIdentifierUrl =>
      "$baseUrl/carton-by-identifier/:identifier/";

  static String get verifyCartonUrl => "$baseUrl/packer/verify-carton/";

  // /basket/<str:identifier>/
  static String get basketUrl => "$baseUrl/basket/:id/";

  //damage product transfer
  static String get damagedProductTransfer =>
      "$baseUrl/transfer-damaged-products/";
  static String get damagedProductReceiveUrl =>
      "$baseUrl/damaged-units/assign/";

  // getStockItemsUrl :/stores/products/
  static String get getStoreUrl => "$baseUrl/stores/";
  static String get getStockItemsUrl =>
      "$baseUrl/stores/products/?store_id=value";
  static String get stockVerificationUrl =>
      "$baseUrl/stores/stock-verifications/";
  // singleUnitVerificationUrl
  static String get singleUnitVerificationUrl =>
      "$baseUrl/single-unit-verification/";

  // /product-availability-by-unit
  static String get productAvailabilityUrl =>
      "$baseUrl/product-availabilities/";
  // product-unit-verification/
  static String get productUnitVerificationUrl =>
      "$baseUrl/product-unit-verification/";

  //getAuditViewUrl
  static String get getAuditViewUrl => "$baseUrl/audit-view/";

  static String get postCartonProductTagsUrl => "$baseUrl/scanned_carton/";

  // ---------------------------- driver -------------------------------
  static String get driverScanBasketsUrl => "$baseUrl/driver/scan-baskets/";
  // /driver/in-transit-transfers/
  static String get driverInTransitTransfersUrl =>
      "$baseUrl/driver/in-transit-transfers/";

  // ---------------------------- manager -------------------------------
  // manager/transfers/in-transit/
  static String get managerInTransitTransfersUrl =>
      "$baseUrl/manager/transfers/in-transit/";
  // manager/transfers/15/receive
  static String get managerReceiveTransferUrl =>
      "$baseUrl/manager/transfers/:id/receive/";

  //damage product url
  static String get damageProductUnitUrl => "$baseUrl/product_units/";
  static String get markDamageUrl => "$baseUrl/mark-damaged/";
  static String get qrDamageUrl => "$baseUrl/qr-damaged/";
  static String get scanRackDamageUrl => "$baseUrl/rack/products/";
  static String get damageRequestUrl => "$baseUrl/mark-damaged-units-to-rack/";

  // inventory transfer request
  static String get inventoryTransferRequestList =>
      "$baseUrl/inventory-transfer-requests/";
  static String get inventoryTransferRequestDetails =>
      "$baseUrl/inventory-transfer-requests/:id/";
  // scan-return-basket/ return-to-warehouse/
  static String get scanReturnBasketUrl => "$baseUrl/staff/scan-return-basket/";
  static String get returnProductToWarehouseUrl =>
      "$baseUrl/staff/return-products-to-warehouse/";

  //expired products
  static String get expiryProductUrl => "$baseUrl/near-expiry-products";
  static String get expiryProductDetailsUrl =>
      "$baseUrl/near-expiry-products/id";

  // check package
  static String get checkPackageUrl => "$baseUrl/orders/check-package/";
  static String get packageReturnUrl => "$baseUrl/staff/store/order-packages/";
  static String packageReturnDetailsUrl(int id) =>
      "$baseUrl/staff/orders/$id/return-package/";

  //  lost items
  static String lostItems(int? id) =>
      id != null ? "$orderUrl/$id/lost-items/" : "$orderUrl/lost-items/";

  // leave request
  static String get leaveRequestUrl => "$baseUrl/staff/api/packer-leaves/";

  // fruits and vegetables
  static String get fruitsVegsUrl => "$baseUrl/packer/produce/units/today/";

  static String get fruitsVegsAssessUrl =>
      "$baseUrl/packer/produce/units/assess/";

  // product checker
  static String get productCheckerUrl =>
      "$baseUrl/packer/produce/checker/units/today/";

  // product checker assess
  static String get productCheckerAssessUrl =>
      "$baseUrl/packer/produce/units/verify/";

  // checked products
  static String get checkedProductsUrl =>
      "$baseUrl/packer/produce/units/quarantined/";

  // stock audit
  static String get stockAuditUrl => "$_packerUrl/stock-audit/";
  static String get stockAuditStartUrl => "$_packerUrl/stock-audit/start/";
  static String get stockAuditItemUrl => "$_packerUrl/stock-audit/item/";
  static String get stockAuditCompleteUrl =>
      "$_packerUrl/stock-audit/complete/";

  // store cleanliness
  static String get storeCleanlinessUrl => "$baseUrl/staff/store-cleanliness/";
  static String get storeCleanlinessUnavailableUrl =>
      "$baseUrl/staff/store-cleanliness/unavailable/";
  static String get storeCleanlinessUploadUrl =>
      "$baseUrl/staff/store-cleanliness/upload/";
}
