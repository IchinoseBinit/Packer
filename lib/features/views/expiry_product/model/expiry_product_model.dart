class ExpiredProductModel {
  late final String? next;
  late final String? previous;
  late final bool hasNextPage;
  late final int page;
  late final List<Results> results;

  ExpiredProductModel(
      {this.next,
      this.previous,
      required this.hasNextPage,
      required this.page,
      required this.results});

  ExpiredProductModel.fromJson(Map<String, dynamic> json) {
    next = json['next'];
    previous = json['previous'];
    hasNextPage = json['has_next_page'];
    page = json['page'];
    if (json['results'] != null) {
      results = <Results>[];
      json['results'].forEach((v) {
        results.add(Results.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['next'] = next;
    data['previous'] = previous;
    data['has_next_page'] = hasNextPage;
    data['page'] = page;
    data['results'] = results.map((v) => v.toJson()).toList();
    return data;
  }
}

class Results {
  late final int productId;
  late final String productName;
  late final int totalUnits;
  late final List<String> unitTags;

  Results(
      {required this.productId,
      required this.productName,
      required this.totalUnits,
      required this.unitTags});

  Results.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    totalUnits = json['total_units'];
    unitTags = json['unit_tags'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['product_name'] = productName;
    data['total_units'] = totalUnits;
    data['unit_tags'] = unitTags;
    return data;
  }
}
