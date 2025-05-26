import 'package:packer/enum/environment_config.dart';

class AppUrls {
  //static const String _baseUrl = "http://192.168.1.98:8000/categories";

  static const String _productionDomainnUrl = "dropit.com.np";
  static const String _stagingdomainURL = "13.211.205.215:8000";
  // static const String _stagingdomainURL = "dropit.com.np";

  static final String _baseUrl = EnvironmentConfig.when(
    production: _productionUrl,
    staging: _stagingURL,
  );

  static const String _productionUrl = "https://$_productionDomainnUrl";
  static const String _stagingURL = "http://$_stagingdomainURL";

  static final String baseUrl = EnvironmentConfig.when(
    production: _productionUrl,
    staging: _stagingURL,
  );

  // static const String _domainUrl = "13.211.205.215:8000";

  // static const String _domainUrl = "192.168.1.73:8000";
  // static const String _domainUrl = "192.168.100.183:8000";
  // static const String _baseUrl = "http://$_domainUrl";

  // static const String _domainUrl = "dropit.com.np";
  // static const String _baseUrl = "https://$_domainUrl";
  // static const String _baseUrl = "https://dropit.com.np";

  static String imageUrl = _baseUrl;

  static final String _authUrl = "$_baseUrl/auth";

  // static  String registerUrl = "$_authUrl/register";
  static String loginUrl = "$_authUrl/api/token/";
  static String verifyOtpUrl = "$_authUrl/verify-otp";
  static String refreshTokenUrl = "$_authUrl/verify-otp/refresh";
  static String logoutUrl = "$_authUrl/logout";

  // Category
  static String categoryUrl = "$_baseUrl/categories";
  static String subcategoryUrl = "$_baseUrl/subcategories";
  static String productUrl = "$_baseUrl/products";
  //static  String productImageUrl = "$_baseUrl/products/image"; productimage/
  static String productImageUrl = "$_baseUrl/product/productimage";
  //http://13.211.205.215:8000/admin/product/productimage/
  static String cartUrl = "$_baseUrl/cart-items";
  // static  String increamentCartUrl = "$_baseUrl/cart-items";

  //login api path
  static String loginUrldemo = "$_authUrl/api/token/";

  static final String _packerUrl = "$_baseUrl/staff/packer";

  static String orderUrl = "$_baseUrl/orders";

  static String orderDetailsUrl = "$orderUrl/id/rider-detail";
  static String acknowledgeOrderUrl = "$_baseUrl/staff/orders";
  static String billOrderUrl = "$orderUrl/id/bill";
  //
  static String orderQrImageUrl = "$orderUrl/view-qr";
  static String homeImageUrl = "$orderUrl/id/home-image";

  static String productPostDetail = "$orderUrl/basket-order/";

  static String packerOnlineStatus = "$_baseUrl/staff/packer/online-status/";
  static String packerSummaryUrl = "$_packerUrl/summary/";
  static String packerStoreLocationUrl = "$_packerUrl/store-location";

  static String packerAvailability = "$_baseUrl/staff/packer/availability/";

  static String getOrdersByStatusUrl = "$orderUrl/get-order?status=";
  static String getLatestOrdersUrl = "$orderUrl/get-order";
  static String getUnsettledOrdersUrl = "$_packerUrl/unsettled-orders";
  static String createSettlementRequestUrl =
      "$_packerUrl/create-settlement-request";
  static String orderSummaryUrl = "$_packerUrl/weekly-summary/";
  static String dailySummaryUrl = "$_packerUrl/order-view/";

  static String fcmTokenUrl = "$_baseUrl/notification/register-device";

  // packer_transfer
  static String packerTransferUrl = "$_baseUrl/packer/transfers/";
  static String packerTransferDetailsUrl = "$_baseUrl/packer/transfers/id/";
  // scan-unit
  static String scanUnitUrl = "$_baseUrl/packer/transfers/id/scan-units/";
  // complete
  static String completeTransferUrl = "$_baseUrl/packer/transfers/id/complete/";
  // low-stock
  static String lowStockUrl = "$_baseUrl/packer/low-stock-products/";

  // manager_transfer
  static String managerTransferUrl = "$_baseUrl/store/transfers/";
  static String managerTransferDetailsUrl = "$_baseUrl/store/transfers/id/";
  // verify-units
  static String verifyUnitsUrl = "$_baseUrl/store/transfers/id/verify-units/";
  // updateRackUrl
  static String updateRackUrl = "$_baseUrl/update-product-availabilty-rack/";
  // accept
  static String acceptTransferUrl = "$_baseUrl/store/transfers/id/accept/";

  static String basketClearUrl = "$_baseUrl/basket/id/clear/";

  // staff/scan-basket
  static String scanBasketUrl = "$_baseUrl/staff/scan-basket/";

  // add-products
  static String addProductsUrl = "$_baseUrl/staff/add-products/";
  // transfer-basket-inventory/
  static String transferBasketInventoryUrl =
      "$_baseUrl/staff/transfer-basket-inventory/";

  // carton_info/<str:carton_identifier>/
  static String cartonInfoUrl = "$_baseUrl/carton_info/:id/";

    static String verifyCartonUrl = "$_baseUrl/packer/verify-carton/";


  // /basket/<str:identifier>/
  static String basketUrl = "$_baseUrl/basket/:id/";
}
