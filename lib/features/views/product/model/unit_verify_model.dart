// product_unit_tags = request.data.get('product_units', [])
//         previous_rack_name = request.data.get('previous_rack')
//         new_rack_name = request.data.get('new_rack')
// Binit
// hunxa eti pathaune hai pathauda chei post garda
// Binit
// product_id = request.data.get('product') yo panichha

class UnitVerifyModel {
  List<String>? productUnitTags;
  String previousRackName;
  String? newRackName;
  int? product;

  UnitVerifyModel({
    this.productUnitTags,
    required this.previousRackName,
    this.newRackName,
    this.product,
  });

  // copyWith
  UnitVerifyModel copyWith({
    List<String>? productUnitTags,
    String? previousRackName,
    String? newRackName,
    int? product,
  }) {
    return UnitVerifyModel(
      productUnitTags: productUnitTags ?? this.productUnitTags,
      previousRackName: previousRackName ?? this.previousRackName,
      newRackName: newRackName ?? this.newRackName,
      product: product ?? this.product,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'product_unit_tags': productUnitTags,
      'previous_rack': previousRackName,
      'new_rack': newRackName,
      'product': product,
    };
  }
}
