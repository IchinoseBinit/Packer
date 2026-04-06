class PackageReturnModel {
  int? totalOrders;
  List<Data>? data;

  PackageReturnModel({this.totalOrders, this.data});

  PackageReturnModel.fromJson(Map<String, dynamic> json) {
    totalOrders = json['total_orders'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_orders'] = this.totalOrders;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  int? orderId;
  List<Packages>? packages;

  Data({this.orderId, this.packages});

  Data.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'];
    if (json['packages'] != null) {
      packages = <Packages>[];
      json['packages'].forEach((v) {
        packages!.add(Packages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = this.orderId;
    if (this.packages != null) {
      data['packages'] = this.packages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Packages {
  String? identifier;
  String? status;
  String? rack;

  Packages({
    this.identifier,
    this.status,
    this.rack,
  });

  Packages.fromJson(Map<String, dynamic> json) {
    identifier = json['identifier'];
    status = json['status'];
    rack = json['rack'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['identifier'] = this.identifier;
    data['status'] = this.status;
    data['rack'] = this.rack;
    return data;
  }
}
