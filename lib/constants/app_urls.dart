class AppUrls {
  //static const String _baseUrl = "http://192.168.1.98:8000/categories";

  static const String _domainUrl = "13.211.205.215:8000";

  // static const String _domainUrl = "192.168.1.73:8000";
  // static const String _domainUrl = "192.168.100.183:8000";
  // static const String _baseUrl = "http://$_domainUrl";

  // static const String _domainUrl = "dropit.com.np";
  // static const String _baseUrl = "https://$_domainUrl";
  static const String _baseUrl = "https://dropit.com.np";

  static const String imageUrl = _baseUrl;

  static const String _authUrl = "$_baseUrl/auth";

  // static const String registerUrl = "$_authUrl/register";
  static const String loginUrl = "$_authUrl/api/token/";
  static const String verifyOtpUrl = "$_authUrl/verify-otp";
  static const String refreshTokenUrl = "$_authUrl/verify-otp/refresh";
  static const String logoutUrl = "$_authUrl/logout";

  // Category
  static const String categoryUrl = "$_baseUrl/categories";
  static const String subcategoryUrl = "$_baseUrl/subcategories";
  static const String productUrl = "$_baseUrl/products";
  //static const String productImageUrl = "$_baseUrl/products/image"; productimage/
  static const String productImageUrl = "$_baseUrl/product/productimage";
  //http://13.211.205.215:8000/admin/product/productimage/
  static const String cartUrl = "$_baseUrl/cart-items";
  // static const String increamentCartUrl = "$_baseUrl/cart-items";

  //login api path
  static const String loginUrldemo = "$_authUrl/api/token/";

  static const String _packerUrl = "$_baseUrl/staff/packer";

  static const String orderUrl = "$_baseUrl/orders";

  static const String orderDetailsUrl = "$orderUrl/id/rider-detail";
  static const String acknowledgeOrderUrl = "$_baseUrl/staff/orders";
  static const String billOrderUrl = "$orderUrl/id/bill";
  //
  static const String orderQrImageUrl = "$orderUrl/view-qr";
  static const String homeImageUrl = "$orderUrl/id/home-image";

  static const String productPostDetail = "$orderUrl/basket-order/";

  static const String packerOnlineStatus =
      "$_baseUrl/staff/packer/online-status/";
  static const String packerSummaryUrl = "$_packerUrl/summary/";
  static const String packerStoreLocationUrl = "$_packerUrl/store-location";

  static const String packerAvailability =
      "$_baseUrl/staff/packer/availability/";

  static const String getOrdersByStatusUrl = "$orderUrl/get-order?status=";
  static const String getLatestOrdersUrl = "$orderUrl/get-order";
  static const String getUnsettledOrdersUrl = "$_packerUrl/unsettled-orders";
  static const String createSettlementRequestUrl =
      "$_packerUrl/create-settlement-request";
  static const String orderSummaryUrl = "$_packerUrl/weekly-summary/";
  static const String dailySummaryUrl = "$_packerUrl/order-view/";

  static const String fcmTokenUrl = "$_baseUrl/notification/register-device";

  // packer_transfer
  static const String packerTransferUrl = "$_baseUrl/packer/transfers/";
  static const String packerTransferDetailsUrl =
      "$_baseUrl/packer/transfers/id/";
  // scan-unit
  static const String scanUnitUrl = "$_baseUrl/packer/transfers/id/scan-units/";
  // complete
  static const String completeTransferUrl =
      "$_baseUrl/packer/transfers/id/complete/";
  // low-stock
  static const String lowStockUrl = "$_baseUrl/packer/low-stock-products/";

  // manager_transfer
  static const String managerTransferUrl = "$_baseUrl/store/transfers/";
  static const String managerTransferDetailsUrl =
      "$_baseUrl/store/transfers/id/";
  // verify-units
  static const String verifyUnitsUrl =
      "$_baseUrl/store/transfers/id/verify-units/";
  // updateRackUrl
  static const String updateRackUrl =
      "$_baseUrl/update-product-availabilty-rack/";
  // accept
  static const String acceptTransferUrl = "$_baseUrl/store/transfers/id/accept/";

  static const String basketClearUrl = "$_baseUrl/basket/id/clear/";

  // staff/scan-basket
  static const String scanBasketUrl = "$_baseUrl/staff/scan-basket/";

  // add-products
  static const String addProductsUrl = "$_baseUrl/staff/add-products/";
  // transfer-basket-inventory/
  static const String transferBasketInventoryUrl =
      "$_baseUrl/staff/transfer-basket-inventory/";


      // carton_info/<str:carton_identifier>/
  static const String cartonInfoUrl = "$_baseUrl/carton_info/:id/";


  // /basket/<str:identifier>/
  static const String basketUrl = "$_baseUrl/basket/:id/";
}
