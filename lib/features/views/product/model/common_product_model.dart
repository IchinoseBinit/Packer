import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_item_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
import 'package:packer/features/views/product/model/product_avaliability.dart';
import 'package:packer/features/views/stock_verification/model/stock_item_model.dart';

class CommonProductModel {
  late int id;
  late int productId;
  late String productName;
  late String rackName;
  late String image;
  late List<String> productUnits = [];
  late int quantity;
  late String size;
  late String measurement;
  late int scannedCount;
  late final String productCompartment;
  String? status;
  late int plannedQuantity;

  // from productAvailability
  CommonProductModel.fromProductAvailability(
      ProductAvailability productAvailability) {
    productId = productAvailability.productId;
    productName = productAvailability.productName;
    rackName = productAvailability.rackName;
    image = productAvailability.image;
    productUnits = productAvailability.productUnits;
    id = productAvailability.productId;
    quantity = productAvailability.productUnits.length;
    size = "";
    measurement = "";
    scannedCount = 0;
    productCompartment = "";
    plannedQuantity = 0;
  }

  CommonProductModel.fromProductModel(ProductModel productModel) {
    id = productModel.id;
    productId = productModel.productId;
    productName = productModel.productName;
    rackName = productModel.rackName;
    image = productModel.imageUrl;
    quantity = productModel.quantity;
    size = productModel.size;
    measurement = productModel.measurement;
    scannedCount = productModel.scannedCount;
    productCompartment = "";
    plannedQuantity = 0;
  }

  CommonProductModel.fromProductDetails(ProductDetails productDetails) {
    id = productDetails.id;
    productName = productDetails.productName;
    rackName = productDetails.rackName;
    image = productDetails.imageUrl;
    quantity = productDetails.quantity ?? 0;
    size = productDetails.size;
    measurement = productDetails.measurement;
    scannedCount = productDetails.itemScanCount;
    productCompartment = productDetails.productCompartment;
    plannedQuantity = 0;
    productUnits = [];
  }

  // TransferItemModel transferItemModel;
  CommonProductModel.fromTransferItemModel(
      TransferItemModel transferItemModel) {
    id = transferItemModel.id ?? 0;
    productId = transferItemModel.product ?? 0;
    productName = transferItemModel.productName ?? "";
    rackName = transferItemModel.rack ?? "";
    image = transferItemModel.productImage;
    quantity = transferItemModel.quantity ?? 0;
    size = transferItemModel.size.toString();
    measurement = transferItemModel.measurement ?? "";
    scannedCount = transferItemModel.itemScanCount;
    status = transferItemModel.status;
  }

  // final int productId;
  // final String productName;
  // final String size;
  // final String measurement;
  // final int stockQuantity;
  // final int plannedQuantity;
  // final String rackName;
  // final String image;
  // final List<String> productUnits;
  CommonProductModel.fromStockItemModel(StockItemModel stockItemModel) {
    productId = stockItemModel.productId;
    productName = stockItemModel.productName;
    rackName = stockItemModel.rackName;
    image = stockItemModel.image;
    quantity = stockItemModel.stockQuantity;
    size = stockItemModel.size;
    measurement = stockItemModel.measurement;
    plannedQuantity = stockItemModel.plannedQuantity;
    productUnits = stockItemModel.productUnits;
    scannedCount = 0;
    productCompartment = "";
  }
  
  CommonProductModel.fromInventoryTransferRequestItemModel(InventoryTransferRequestItemModel model) {
    productId = model.productId ?? 0;
    productName = model.productName ?? "";
    rackName = model.rackName ?? "";
    image = model.productImage.toString();
    quantity = model.quantity ?? 0;
    size = "";
    measurement = "";
    plannedQuantity = 0;
    productUnits = [];
    scannedCount = 0;
    productCompartment = "";
  }
}
