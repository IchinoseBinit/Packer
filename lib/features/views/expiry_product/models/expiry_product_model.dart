import 'package:packer/controllers/extensions/string_extension.dart';

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
    next = json['next'].toString().toStringConversion();
    previous = json['previous'].toString().toStringConversion();
    hasNextPage = json['has_next_page'];
    page = json['page'].toString().toInt();
    if (json['results'] != null) {
      results = <Results>[];
      json['results'].forEach((v) {
        results.add(Results.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['next'] = next.toString().toStringConversion();
    data['previous'] = previous.toString().toStringConversion();
    data['has_next_page'] = hasNextPage;
    data['page'] = page.toString().toInt();
    data['results'] = results.map((v) => v.toJson()).toList();
    return data;
  }
}

class Results {
  late final int productId;
  late final String productName;
  late final int totalUnits;
  late final String rackName;
  late final List<String> unitTags;

  Results(
      {required this.productId,
      required this.productName,
      required this.totalUnits,
      required this.rackName,
      required this.unitTags});

  Results.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    totalUnits = json['total_units'].toString().toInt();
    unitTags = json['unit_tags'].cast<String>();
    rackName = json['rack']?.toString().toStringConversion() ?? 'N/A';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId.toString().toInt();
    data['product_name'] = productName.toString().toStringConversion();
    data['total_units'] = totalUnits.toString().toInt();
    data['unit_tags'] = unitTags;
    data['rack'] = rackName.toString().toStringConversion();
    return data;
  }
}
