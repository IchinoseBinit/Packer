class InventoryTransferRequestModel {
  int? id;
  String? sourceStore;
  String? destinationStore;
  String? status;
  String? createdBy;
  String? createdAt;

  InventoryTransferRequestModel(
      {this.id,
      this.sourceStore,
      this.destinationStore,
      this.status,
      this.createdBy,
      this.createdAt});

  InventoryTransferRequestModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sourceStore = json['source_store'];
    destinationStore = json['destination_store'];
    status = json['status'];
    createdBy = json['created_by'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['source_store'] = sourceStore;
    data['destination_store'] = destinationStore;
    data['status'] = status;
    data['created_by'] = createdBy;
    data['created_at'] = createdAt;
    return data;
  }
}

class Items {
  String? rackName;
  String? productName;
  int? quantity;

  Items({this.rackName, this.productName, this.quantity});

  Items.fromJson(Map<String, dynamic> json) {
    rackName = json['rack_name'];
    productName = json['product_name'];
    quantity = json['quantity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rack_name'] = rackName;
    data['product_name'] = productName;
    data['quantity'] = quantity;
    return data;
  }
}
