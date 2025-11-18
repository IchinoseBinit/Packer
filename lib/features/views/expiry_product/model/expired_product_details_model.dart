class ExpiredProductDetailsModel {
  late final int productId;
  late final String productName;
  late final List<Cartons> cartons;

  ExpiredProductDetailsModel(
      {required this.productId,
      required this.productName,
      required this.cartons});

  ExpiredProductDetailsModel.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    if (json['cartons'] != null) {
      cartons = <Cartons>[];
      json['cartons'].forEach((v) {
        cartons.add(Cartons.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['product_name'] = productName;
    if (cartons.isNotEmpty) {
      data['cartons'] = cartons.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Cartons {
  late final int cartonId;
  late final String expiryDate;
  late final String manufacturingDate;
  late final int daysLeft;
  late final List<String> unitTags;

  Cartons(
      {required this.cartonId,
      required this.expiryDate,
      required this.manufacturingDate,
      required this.daysLeft,
      required this.unitTags});

  Cartons.fromJson(Map<String, dynamic> json) {
    cartonId = json['carton_id'];
    expiryDate = json['expiry_date'];
    manufacturingDate = json['manufacturing_date'];
    daysLeft = json['days_left'];
    unitTags = json['unit_tags'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['carton_id'] = cartonId;
    data['expiry_date'] = expiryDate;
    data['manufacturing_date'] = manufacturingDate;
    data['days_left'] = daysLeft;
    data['unit_tags'] = unitTags;
    return data;
  }
}
